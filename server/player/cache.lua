local _queue = {}
local _players = {}
local _users = {}
local _characters = {}

---@class PlayersCache
local playersCache = {}

function playersCache.addQueue(loginId, userId)
    _queue[loginId] = userId
end

function playersCache.getQueue(loginId)
    return _queue[loginId]
end

function playersCache.removeQueue(loginId)
    _queue[loginId] = nil
end

function playersCache.addPlayer(src, player)
    _players[src] = player
end

function playersCache.getPlayer(src)
    return _players[src]
end

function playersCache.getAllPlayers()
    return _players
end

function playersCache.removePlayer(src)
    local player = _players[src]

    _users[player.userId] = nil

    if player and player.charId then
        _characters[player.charId] = nil
    end

    _players[src] = nil
end

function playersCache.addCharLink(src, charId)
    _characters[charId] = src
end

function playersCache.addUserLink(src, userId)
    _users[userId] = src
end

function playersCache.getByUserId(userId)
    local src = _users[userId]

    return src and _players[src] or false
end

function playersCache.getByCharId(charId)
    local src = _characters[charId]

    return src and _players[src] or false
end

return playersCache