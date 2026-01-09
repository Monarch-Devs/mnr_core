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
---@return table | nil, number | nil
lib.callback.register('mnr_core:server:GetCharacters', function(source)
    if not Players[source] then
        return nil, nil
    end

    local userId = Players[source].userId
    local characters = db.getUserCharacters(userId)
    local slots = db.getUserCharSlots(userId)

    return characters, slots
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

    local slots = db.getUserCharSlots(userId)
    if slot > slots or slot < 1 then
        return false, 'invalid_slot'
    end

    local characters = db.getUserCharacters(userId)
    for _, char in ipairs(characters) do
        if char.slot == slot then
            return false, 'slot_taken'
        end
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
---@return table | false, vector4 | nil
lib.callback.register('mnr_core:server:SelectedCharacter', function(source, slot)
    if not Players[source] then
        return false, nil
    end

    if type(slot) ~= 'number' then
        return false, nil
    end

    local userId = Players[source].userId

    local characters = db.getUserCharacters(userId)
    local selected = false
    for _, char in ipairs(characters) do
        if char.slot == slot then
            Players[source]:loadChar(char)
            selected = char
            break
        end
    end

    if not selected then
        return false, nil
    end

    local position = db.getSpawnPosition(Players[source].charId)

    if not position then
        position = spawn.start
    end

    return selected, position
end)

local function onPlayerDropped(reason)
    local src = source

    Players[src]:save()
    Players[src] = nil
    GlobalState.OnlinePlayers -= 1
end

AddEventHandler('playerDropped', onPlayerDropped)