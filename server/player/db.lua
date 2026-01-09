---@todo MERGE SLOTS AND CHARACTERS IN A SINGLE FUNCTION

local db = {}

local GET_USER = 'SELECT `userId` FROM `users` WHERE `license2` = ?'
local UPDATE_USER = 'UPDATE `users` SET `license` = COALESCE(?, `license`), `fivem` = COALESCE(?, `fivem`), `steam` = COALESCE(?, `steam`), `discord` = COALESCE(?, `discord`) WHERE `userId` = ?'
local CREATE_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?)'
local CREATE_CHAR_SLOTS = 'INSERT IGNORE INTO `char_slots` (`userId`, `slots`) VALUES (?, 2)'

-- Database query used to register or update a user during login
---@todo Reduce query number, add slots as param to implement custom perms later
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

        MySQL.prepare.await(CREATE_CHAR_SLOTS, {userId})

        return userId, nil
    end
end

local GET_USER_CHAR_SLOTS = 'SELECT `slots` FROM `char_slots` WHERE `userId` = ?'

-- Database query used to get the maximum character slots for a user
---@param userId number
---@return number
function db.getUserCharSlots(userId)
    local slots = MySQL.prepare.await(GET_USER_CHAR_SLOTS, { userId })

    return slots or 2
end

local CREATE_CHARACTER = 'INSERT INTO `characters` (`userId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate`) VALUES (?, ?, ?, ?, ?, ?, ?)'

-- Database query used to create a new character for a user
---@param userId number
---@param slot number
---@param character table
function db.createCharacter(userId, slot, character)
    local charId = MySQL.prepare.await(CREATE_CHARACTER, {
        userId,
        slot,
        character.firstname,
        character.lastname,
        character.gender,
        character.origin,
        character.birthdate
    })

    return charId
end

local GET_USER_CHARACTERS = 'SELECT `charId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? ORDER BY `slot` ASC'
-- Database query used to get all characters for a user
---@param userId number
function db.getUserCharacters(userId)
    local characters = MySQL.prepare.await(GET_USER_CHARACTERS, { userId })

    return characters or {}
end

return db