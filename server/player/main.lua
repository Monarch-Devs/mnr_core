local helpers = require 'server.player.helpers'
local db = require 'server.player.db'

local PRIMARY_IDENTIFIER = GetConvar('mnr:primary_identifier', 'license2')

GlobalState:set('onlinePlayers', 0, true)
Players = {}

local function onPlayerConnecting(name, _, deferrals)
    local src = source

    local identifiers = helpers.getIdentifiersBySource(src)
    if not identifiers[PRIMARY_IDENTIFIER] then
        deferrals.done(('Hi %s, primary identifier not found. Missing "%s"'):format(name, PRIMARY_IDENTIFIER))
        return
    end

    deferrals.defer()

    Wait(0)

    deferrals.update(('Hi %s. We are checking your identifiers in database...'):format(name))

    local userId, err = db.userLogin(identifiers)

    Wait(0)

    if userId then
        deferrals.done()
    else
        deferrals.done(err)
    end
end

AddEventHandler('playerConnecting', onPlayerConnecting)