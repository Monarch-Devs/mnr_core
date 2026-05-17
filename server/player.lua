local adaptiveCard = GetConvarBool('mnr:adaptiveCard', true) and GetResourceState('mnr_adaptivecard') == 'started'
local maxCharacters = GetConvarInt('mnr:maxCharacters', 2)

local config = require 'config.server'

local groupsCache = require 'server.groups.cache'

local playersCache = require 'server.player.cache'
local utils = require 'server.player.utils'
local db = require 'server.player.db'
local MnrPlayer = require 'server.player.class'

GlobalState:set('MaxClients', GetConvarInt('sv_maxclients', 48), true)
GlobalState:set('OnlinePlayers', 0, true)

local function _doLogin(loginId, name, deferrals)
    deferrals.update(('Hi %s. We are checking your identifiers in database...'):format(name))

    local identifiers = utils.getIdentifiers(loginId)
    if not identifiers.license2 then
        deferrals.done('Missing license2.')
        return
    end

    local userId = db.userLogin(identifiers, maxCharacters)
    if userId then
        playersCache.addQueue(loginId, userId --[[@as number]])
        deferrals.done()
    else
        deferrals.done('Login error, retry later.')
    end
end

-- Function attached to "playerConnecting" handler. Note: loginId is converted to string because in playerJoining the type is string
---@param name string The name of the connecting player
---@param deferrals FiveMConnectingDeferrals
local function onPlayerConnecting(name, _, deferrals)
    local loginId = tostring(source)

    deferrals.defer()

    Wait(0)

    if GlobalState.OnlinePlayers == GlobalState.MaxClients then
        deferrals.done('Max Players limit reached, retry when a player slot becomes available.')
        return
    end

    if adaptiveCard then
        exports.mnr_adaptivecard:PresentCard(name, deferrals, function(accepted)
            if not accepted then
                return
            end

            _doLogin(loginId, name, deferrals)
        end)
    else
        _doLogin(loginId, name, deferrals)
    end
end

AddEventHandler('playerConnecting', onPlayerConnecting)

---@param loginId string
local function onPlayerJoining(loginId)
    local src = source
    local userId = playersCache.getQueue(loginId)

    if not userId then
        DropPlayer(src, 'Session error, please reconnect.')
        return
    end

    playersCache.addPlayer(src, MnrPlayer.new(userId, src))
    playersCache.addUserLink(src, userId)
    playersCache.removeQueue(loginId)

    GlobalState.OnlinePlayers += 1
end

AddEventHandler('playerJoining', onPlayerJoining)

-- Callback to get the characters and slots for a user
---@param source number
---@return number | boolean, table | boolean
lib.callback.register('mnr_core:server:GetCharacters', function(source)
    local player = playersCache.getPlayer(source)
    if not player then
        return false, false
    end

    local userId = player.userId
    local slots = db.getUserSlots(userId) or maxCharacters
    local characters = db.getUserCharacters(userId, slots)

    return slots, characters
end)

-- Callback to validate character data and create a new character
---@param source number
---@param character table
---@param slot number
---@return number | false, string | nil
lib.callback.register('mnr_core:server:CreateCharacter', function(source, character, slot)
    local player = playersCache.getPlayer(source)
    if not player then
        return false, 'no_player'
    end

    local userId = player.userId
    local slots = db.getUserSlots(userId) or maxCharacters
    local characters = db.getUserCharacters(userId, slots)

    if slot > slots or slot < 1 then
        return false, 'invalid_slot'
    end

    if characters[slot] then
        return false, 'slot_taken'
    end

    local data = utils.checkCharacter(character)
    if not data then
        return false, 'invalid_data'
    end

    local charId = db.createCharacter(userId, slot, data)
    if not charId then
        return false, 'creation_failed'
    end

    return charId, nil
end)

-- Callback to select a character and load its data
---@param source number
---@param slot number
---@return boolean loaded
lib.callback.register('mnr_core:server:SelectCharacter', function(source, slot)
    local player = playersCache.getPlayer(source)
    if not player or type(slot) ~= 'number' then
        return false
    end

    local success, err = player:loadChar(slot)
    if not success then
        ---@todo print of error
        return false
    end

    playersCache.addCharLink(source, player.charId)

    for _, data in ipairs(player.groups or {}) do
        if type(data) == 'table' then
            local group = groupsCache.getGroup(data.name)
            if group then
                group.online[character.charId] = source
            end
        end
    end

    return true
end)

local function onPlayerDropped(reason)
    local src = source

    GlobalState.OnlinePlayers -= 1

    local player = playersCache.getPlayer(src)
    if not player then
        return
    end

    player:saveChar()

    for _, data in ipairs(player.groups or {}) do
        if type(data) == 'table' then
            local group = groupsCache.getGroup(data.name)
            if group then
                group.online[player.charId] = nil
            end
        end
    end

    playersCache.removePlayer(src)
end

AddEventHandler('playerDropped', onPlayerDropped)

---@param source number
---@param targetCharId number
---@param groupName string
---@param grade number
lib.callback.register('mnr_core:server:HirePlayer', function(source, targetCharId, groupName, grade)
    local caller = playersCache.getPlayer(source)
    if not caller then
        return false, 'no_caller'
    end

    if not caller:hasGroupPermission(groupName, 'bossPerms', 'hire') then
        return false, 'no_permission'
    end

    local target = playersCache.getByCharId(targetCharId)
    if not target then
        return false, 'target_offline'
    end

    local group = groupsCache.getGroup(groupName)
    if not group then
        return false, 'invalid_group'
    end

    return target:addGroup(group.cat, groupName, grade)
end)

---@param source number
---@param targetCharId number
---@param groupName string
---@param grade number
lib.callback.register('mnr_core:server:PromotePlayer', function(source, targetCharId, groupName, grade)
    local caller = playersCache.getPlayer(source)
    if not caller then
        return false, 'no_caller'
    end

    if not caller:hasGroupPermission(groupName, 'bossPerms', 'promote') then
        return false, 'no_permission'
    end

    local target = playersCache.getByCharId(targetCharId)
    if not target then
        return false, 'target_offline'
    end

    local _, slot = target:getGroup(groupName)
    if not slot then
        return false, 'not_in_group'
    end

    return target:setGrade(slot, grade)
end)

---@param source number
---@param targetCharId number
---@param groupName string
lib.callback.register('mnr_core:server:FirePlayer', function(source, targetCharId, groupName)
    local caller = playersCache.getPlayer(source)
    if not caller then return false, 'no_caller' end

    if not caller:hasGroupPermission(groupName, 'bossPerms', 'fire') then
        return false, 'no_permission'
    end

    local target = playersCache.getByCharId(targetCharId)
    if not target then return false, 'target_offline' end

    local _, slot = target:getGroup(groupName)
    if not slot then return false, 'not_in_group' end

    return target:removeGroup(slot)
end)

---@todo Make this function more modular integrating internal functions in class and call everything here
lib.cron.new(('*/%d * * * *'):format(config.interval), function()
    for _, player in pairs(playersCache.getAllPlayers()) do
        if not player.charId then goto skip_degrade end

        player:degradeStatus()

        ::skip_degrade::
    end
end)

-- Function to take data from specific fields/subfields of a player (What frameworks didn't done for years)
---@param source number The source of the player
---@param field string The field of player class (bio, money, etc.)
---@param sub? string The subfield of player class (firstname, bank, etc.)
---@return unknown | false value The value contained in the field/subfield
local function getPlayerData(source, field, sub)
    local src = source

    local player = playersCache.getPlayer(src)
    if not player then
        return false
    end

    if not sub then
        return player[field] and player[field] or false
    else
        return player[field] and player[field][sub] or false
    end
end

exports('GetPlayerData', getPlayerData)

exports('GetPlayerByCharId', function(charId)
    return playersCache.getByCharId(charId)
end)

exports('GetPlayerByUserId', function(userId)
    return playersCache.getByUserId(userId)
end)