local spawn = require 'config.spawn'

local helper = require 'server.player.helper'
local db = require 'server.player.db'
local MnrPlayer = require 'server.player.class'

GlobalState:set('OnlinePlayers', 0, true)

Players = {}

local function onPlayerConnecting(name, _, deferrals)
    local src = source

    local identifiers = helper.getIdentifiersBySource(src)
    if not identifiers.license2 then
        deferrals.done(('Hi %s. We didn\'t find a valid identifier (license2)'):format(name))
        return
    end

    deferrals.defer()

    Wait(0)

    deferrals.update(('Hi %s. We are checking your identifiers in database...'):format(name))

    local userId, err = db.userLogin(identifiers)

    Wait(0)

    if not userId then
        deferrals.done(err)
        return
    end

    Players[src] = MnrPlayer.new(userId)
    deferrals.done()
    GlobalState.OnlinePlayers += 1
end

AddEventHandler('playerConnecting', onPlayerConnecting)

-- Callback to get the characters and slots for a user
---@param source number
---@return number | nil, table | nil
lib.callback.register('mnr_core:server:GetCharacters', function(source)
    if not Players[source] then
        return nil, nil
    end

    local userId = Players[source].userId
    local slots, characters = db.getUserData(userId)

    return slots, characters
end)

-- Callback to validate character data and create a new character
---@param source number
---@param character table
---@param slot number
---@return number | false, string | nil
lib.callback.register('mnr_core:server:CreateCharacter', function(source, character, slot)
    if not Players[source] then
        return false, 'no_player'
    end

    local userId = Players[source].userId

    local slots, characters = db.getUserData(userId)

    if slot > slots or slot < 1 then
        return false, 'invalid_slot'
    end

    if characters[slot] ~= false then
        return false, 'slot_taken'
    end

    local data = helper.checkCharacter(character)
    if not data then
        return false, 'invalid_data'
    end

    local charId = db.createCharacter(userId, slot, character)
    if not charId then
        return false, 'creation_failed'
    end

    return charId, nil
end)

-- Callback to select a character and load it
---@todo Improve structure
---@param source number
---@param slot number
---@return boolean loaded
lib.callback.register('mnr_core:server:SelectedCharacter', function(source, slot)
    if not Players[source] then
        return false
    end

    if type(slot) ~= 'number' then
        return false
    end

    local userId = Players[source].userId
    local _, characters = db.getUserData(userId)

    if type(characters[slot]) ~= 'table' then
        return false
    end

    Players[source]:loadChar(characters[slot])

    ---@deprecated [SPAWN MODULE] Better a spawn dedicated script

    TriggerClientEvent('mnr_core:client:CharacterLoaded', source, characters[slot])
    TriggerEvent('mnr_core:server:CharacterLoaded', source, characters[slot])

    return true
end)

local function onPlayerDropped(reason)
    local src = source

    Players[src]:save()
    Players[src] = nil
    GlobalState.OnlinePlayers -= 1
end

AddEventHandler('playerDropped', onPlayerDropped)

local function getPlayerData(source, field, sub)
    local src = source
    if not Players[src] then
        return false
    end

    if not sub then
        return Players[field]
    else
        return Players[field][sub]
    end
end

exports('GetPlayerData', getPlayerData)