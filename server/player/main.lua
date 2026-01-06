local helper = require 'server.player.helpers'
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

lib.callback.register('mnr_core:server:CreateCharacter', function(source, character, slot)
    if not Players[source] then
        return false
    end

    local userId = Players[source].userId
    local maxSlots = db.getUserCharSlots(userId)
    if maxSlots < slot then
        return false
    end

    local valid = helper.CheckBio(character)
    if not valid then
        return false
    end

    local charId = db.createCharacter(userId, slot, character)

    if not charId then
        return false
    end

    return charId
end)

RegisterNetEvent('mnr_core:server:SelectedCharacter', function(slot)
    local src = source

    if not Players[src] then
        return
    end


end)

local function onPlayerDropped(reason)
    local src = source

    Players[src]:save()
    Players[src] = nil
    GlobalState.OnlinePlayers -= 1
end

AddEventHandler('playerDropped', onPlayerDropped)