local maxCharacters = GetConvarInt('mnr:maxCharacters', 2)

local spawn = require 'config.spawn'

local store = require 'server.player.store'
local helper = require 'server.player.helper'
local db = require 'server.player.db'
local MnrPlayer = require 'server.player.class'

GlobalState:set('OnlinePlayers', 0, true)

-- Function attached to "playerConnecting" handler. Note: loginId is converted to string because in playerJoining the type is string
---@param name string The name of the connecting player
local function onPlayerConnecting(name, _, deferrals)
    local loginId = tostring(source)

    deferrals.defer()

    deferrals.update(('Hi %s. We are checking your identifiers in database...'):format(name))

    local identifiers = helper.getIdentifiersBySource(loginId)
    if not identifiers.license2 then
        deferrals.done(('Hi %s. We didn\'t find a valid identifier (license2)'):format(name))
        return
    end

    local userId = db.userLogin(identifiers, maxCharacters)

    if userId then
        store.queueSet(loginId, userId --[[@as number]])
        deferrals.done()
    else
        deferrals.done(('Hi %s. There is a problem with user logins, retry later'):format(name))
        return
    end
end

AddEventHandler('playerConnecting', onPlayerConnecting)

---@param loginId string
local function onPlayerJoining(loginId)
    local src = source
    local userId = store.queueGet(loginId)

    if not userId then
        DropPlayer(src, 'Session error, please reconnect.')
        return
    end

    store.set(src, MnrPlayer.new(userId, src))
    store.queueRemove(loginId)

    GlobalState.OnlinePlayers += 1
end

AddEventHandler('playerJoining', onPlayerJoining)

-- Callback to get the characters and slots for a user
---@param source number
---@return number | boolean, table | boolean
lib.callback.register('mnr_core:server:GetCharacters', function(source)
    local player = store.get(source)
    if not player then
        return false, false
    end

    local userId = player.userId
    local slots = db.getUserSlots(userId)
    local characters = db.getUserCharacters(userId, slots or maxCharacters)

    return slots, characters
end)

-- Callback to validate character data and create a new character
---@param source number
---@param character table
---@param slot number
---@return number | false, string | nil
lib.callback.register('mnr_core:server:CreateCharacter', function(source, character, slot)
    local player = store.get(source)
    if not player then
        return false, 'no_player'
    end

    local userId = player.userId
    local slots = db.getUserSlots(userId)
    local characters = db.getUserCharacters(userId, slots)

    if slot > slots or slot < 1 then
        return false, 'invalid_slot'
    end

    if characters[slot] then
        return false, 'slot_taken'
    end

    local data = helper.checkCharacter(character)
    if not data then
        return false, 'invalid_data'
    end

    local charId = db.createCharacter(userId, slot, data)
    if not charId then
        return false, 'creation_failed'
    end

    return charId, nil
end)

-- Callback to select a character and load his bio
---@param source number
---@param slot number
---@return boolean loaded
lib.callback.register('mnr_core:server:SelectedCharacter', function(source, slot)
    local player = store.get(source)
    if not player or type(slot) ~= 'number' then
        return false
    end

    local userId = player.userId
    local character = db.getCharacterBySlot(userId, slot)

    if not character then
        return false
    end

    player:loadChar(character)
    store.setChar(source, character.charId)

    ---@deprecated [SPAWN MODULE] Better a spawn dedicated script

    TriggerClientEvent('mnr_core:client:CharacterLoaded', source, character)
    TriggerEvent('mnr_core:server:CharacterLoaded', source, character)

    return true
end)

local function onPlayerDropped(reason)
    local src = source

    GlobalState.OnlinePlayers = GetNumPlayerIndices()

    local player = store.get(src)
    if not player then
        return
    end

    player:save()
    store.remove(src)
end

AddEventHandler('playerDropped', onPlayerDropped)

-- Function to take data from specific fields/subfields of a player (What frameworks didn't done for years)
---@param source number The source of the player
---@param field string The field of player class (bio, money, etc.)
---@param sub? string The subfield of player class (firstname, bank, etc.)
---@return unknown | false value The value contained in the field/subfield
local function getPlayerData(source, field, sub)
    local src = source

    local player = store.get(src)
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