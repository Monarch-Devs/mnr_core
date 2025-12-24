local db = {}

local GET_USER = 'SELECT `userId` FROM `users` WHERE `license2` = ?'
local UPDATE_USER = 'UPDATE `users` SET `license` = COALESCE(?, `license`), `fivem` = COALESCE(?, `fivem`), `steam` = COALESCE(?, `steam`), `discord` = COALESCE(?, `discord`) WHERE `userId` = ?'
local CREATE_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?)'

-- Database query used to register or update a user during login
---@todo Reduce query number
---@param identifiers table
---@return number | nil, string | nil
function db.userLogin(identifiers)
    local userId = MySQL.prepare.await(GET_USER, { identifiers.license2 })

    if userId then
        MySQL.update.await(UPDATE_USER, {
            identifiers.license,
            identifiers.fivem,
            identifiers.steam,
            identifiers.discord,
            userId
        })

        return userId, nil
    else
        userId = MySQL.prepare.await(CREATE_USER, {
            identifiers.license,
            identifiers.license2,
            identifiers.fivem,
            identifiers.steam,
            identifiers.discord
        })

        if not userId then
            return nil, 'Failed to create user, contact the developer.'
        end

        return userId, nil
    end
end

return db