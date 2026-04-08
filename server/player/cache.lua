local playersCache = {}

local _queue = {}
local _players = {}
local _users = {}
local _characters = {}

-- Function used to add a player with his loginId
---@param loginId string The given temporary ID to connecting player
---@param userId number The ID retrieved from database
function playersCache.addQueue(loginId, userId)
    _queue[loginId] = userId
end

-- Function used to get a player with his loginId after a NetId is assigned to him
---@param loginId string The given temporary ID to connecting player
---@return number userId The ID cached for the player
function playersCache.getQueue(loginId)
    return _queue[loginId]
end

-- Function to cleanup after cache change
---@param loginId string The given temporary ID to connecting player
function playersCache.removeQueue(loginId)
    _queue[loginId] = nil
end

-- Function to add a player with an assigned NetId
---@param src number The NetId of the player
---@param player MnrPlayer
function playersCache.addPlayer(src, player)
    _players[src] = player
end

-- Function to get a player with his NetId
---@param src number The NetId of the player
---@return MnrPlayer
function playersCache.getPlayer(src)
    return _players[src]
end

-- Function to get all players
---@return table _players
function playersCache.getAllPlayers()
    return _players
end

-- Function to cleanup player class after logout
---@param src number The NetId of the player
function playersCache.removePlayer(src)
    local player = _players[src]

    if player and player.charId then
        _characters[player.charId] = nil
    end

    _players[src] = nil
end

-- Function to relate player userId and source (for simplified search)
---@param src number The NetId of the player
---@param userId number The ID of the user
function playersCache.addUserLink(src, userId)
    _users[userId] = src
end

-- Function to get player class from userId
---@param userId number The ID of the user
---@return MnrPlayer | false
function playersCache.getByUserId(userId)
    local src = _users[userId]

    return src and _players[src] or false
end

-- Function to add a link between player charId and source (for simplified search)
---@param src number The NetId of the player
---@param charId number The ID of the character used
function playersCache.setChar(src, charId)
    _characters[charId] = src
end

-- Function to get player class from charId
---@param charId number The ID of the character used
---@return MnrPlayer | false
function playersCache.getByCharId(charId)
    local src = _characters[charId]

    return src and _players[src] or false
end

return playersCache