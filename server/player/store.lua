-- [BETA] Experimental queue/players data store (unlinked only for test)
local store = {}

local _players = {}
local _queue   = {}

function store.queueSet(loginId, userId)
    _queue[loginId] = userId
end

function store.queueGet(loginId)
    return _queue[loginId]
end

function store.queueRemove(loginId)
    _queue[loginId] = nil
end

function store.set(src, player)
    _players[src] = player
end

function store.get(src)
    return _players[src]
end

function store.remove(src)
    _players[src] = nil
end

return store