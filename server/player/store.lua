-- [BETA] Experimental queue/players data store
local store = {}

local _queue = {}
local _players = {}
local _characters = {}

-- Function used to add a player with his loginId
---@param loginId string The given temporary ID to connecting player
---@param userId number The ID retrieved from database
function store.queueSet(loginId, userId)
    _queue[loginId] = userId
end

-- Function used to get a player with his loginId after a NetId is assigned to him
---@param loginId string The given temporary ID to connecting player
---@return number userId The ID stored for the player
function store.queueGet(loginId)
    return _queue[loginId]
end

-- Function to cleanup after store change
---@param loginId string The given temporary ID to connecting player
function store.queueRemove(loginId)
    _queue[loginId] = nil
end

-- Function to add a player with an assigned NetId
---@param src number The NetId of the player
---@param player MnrPlayer
function store.set(src, player)
    _players[src] = player
end

-- Function to get a player with his NetId
---@param src number The NetId of the player
---@return MnrPlayer
function store.get(src)
    return _players[src]
end

-- Function to cleanup player class after logout
---@param src number The NetId of the player
function store.remove(src)
    local player = _players[src]

    if player and player.charId then
        _characters[player.charId] = nil
    end

    _players[src] = nil
end

-- Function to add a link between player charId and source (simplified search)
---@param src number The NetId of the player
---@param charId number The ID of the character used
function store.setChar(src, charId)
    _characters[charId] = src
end

-- Function to get player class from charId
---@param charId number The ID of the character used
function store.getByCharId(charId)
    local src = _characters[charId]

    return src and _players[src] or false
end

return store