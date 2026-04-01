local db = {}

local UPSERT_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `license` = COALESCE(VALUES(`license`), `license`), `fivem` = COALESCE(VALUES(`fivem`), `fivem`), `steam` = COALESCE(VALUES(`steam`), `steam`), `discord` = COALESCE(VALUES(`discord`), `discord`)'
local GET_USER_ID = 'SELECT `userId` FROM `users` WHERE `license2` = ? LIMIT 1'
-- Database query used to register or update a user during login
---@param identifiers table
---@return number | boolean
function db.userLogin(identifiers)
    MySQL.prepare.await(UPSERT_USER, { identifiers.license, identifiers.license2, identifiers.fivem, identifiers.steam, identifiers.discord })

    local userId = MySQL.scalar.await(GET_USER_ID, { identifiers.license2 })

    if not userId then
        return false
    end

    return userId
end

local GET_SLOTS = 'SELECT `slots` FROM `char_slots` WHERE `userId` = ? LIMIT 1'
-- Database query used to get user's character max slots
---@param userId number
---@return slots number
function db.getUserSlots(userId)
    local slots = MySQL.scalar.await(GET_SLOTS, { userId })

    if not slots then
        return false
    end

    return slots
end

local CREATE_SLOTS = 'INSERT IGNORE INTO `char_slots` (`userId`, `slots`) VALUES (?, ?)'
-- Database query used to initialize user's character max slots
---@param userId number
---@param maxCharacters number
function db.initUserSlots(userId, maxCharacters)
    MySQL.prepare.await(CREATE_SLOTS, { userId, maxCharacters })
end

local GET_CHARACTERS = 'SELECT `charId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? ORDER BY `slot` ASC'
-- Database query used to get user's character slots and all their characters
---@param userId number
---@return number, table
function db.getUserCharacters(userId, slots)
    local rows = MySQL.query.await(GET_CHARACTERS, { userId }) or {}

    local characters = {}
    for i = 1, slots do
        characters[i] = false
    end

    for _, row in ipairs(rows) do
        characters[row.slot] = {
            charId = row.charId,
            firstname = row.firstname,
            lastname = row.lastname,
            gender = row.gender,
            origin = row.origin,
            birthdate = row.birthdate,
        }
    end

    return characters
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

return db