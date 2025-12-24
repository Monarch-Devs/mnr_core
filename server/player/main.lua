local helpers = require 'server.player.helpers'
local db = require 'server.player.db'
local MnrPlayer = require 'server.player.class'

GlobalState:set('onlinePlayers', 0, true)
Players = {}

local function onPlayerConnecting(name, _, deferrals)
    local src = source

    local identifiers = helpers.getIdentifiersBySource(src)
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
end

AddEventHandler('playerConnecting', onPlayerConnecting)