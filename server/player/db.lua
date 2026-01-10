local db = {}

local UPSERT_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `license` = COALESCE(VALUES(`license`), `license`), `fivem` = COALESCE(VALUES(`fivem`), `fivem`), `steam` = COALESCE(VALUES(`steam`), `steam`), `discord` = COALESCE(VALUES(`discord`), `discord`)'
local CREATE_SLOTS = 'INSERT IGNORE INTO `char_slots` (`userId`, `slots`) VALUES (?, 2)'
-- Database query used to register or update a user during login
---@todo Add slots as param to implement custom perms later
---@param identifiers table
---@return number | nil, string | nil
function db.userLogin(identifiers)
    local userId = MySQL.prepare.await(UPSERT_USER, {
        identifiers.license,
        identifiers.license2,
        identifiers.fivem,
        identifiers.steam,
        identifiers.discord
    })

    if not userId then
        return nil, 'Failed to update/create user'
    end

    MySQL.prepare.await(CREATE_SLOTS, {userId})

    return userId, nil
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

local GET_USER_DATA = [[
    SELECT
        char_slots.slots,
        characters.charId,
        characters.slot, 
        characters.firstname, 
        characters.lastname, 
        characters.gender, 
        characters.origin, 
        characters.birthdate 
    FROM char_slots
    LEFT JOIN characters ON char_slots.userId = characters.userId
    WHERE char_slots.userId = ?
    ORDER BY characters.slot ASC
]]
-- Database query used to get user's character slots and all their characters
---@param userId number
---@return number, table
function db.getUserData(userId)
    local result = MySQL.query.await(GET_USER_DATA, { userId })

    if not result or #result == 0 then
        return 2, {}
    end

    local slots = result[1].slots
    local characters = {}

    for slot = 1, slots do
        characters[slot] = false
    end

    for _, row in ipairs(result) do
        if row.charId then
            characters[row.slot] = {
                charId = row.charId,
                firstname = row.firstname,
                lastname = row.lastname,
                gender = row.gender,
                origin = row.origin,
                birthdate = row.birthdate
            }
        end
    end

    return slots, characters
end

return db