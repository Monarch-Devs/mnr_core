local db = {}

local UPSERT_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `license` = COALESCE(VALUES(`license`), `license`), `fivem` = COALESCE(VALUES(`fivem`), `fivem`), `steam` = COALESCE(VALUES(`steam`), `steam`), `discord` = COALESCE(VALUES(`discord`), `discord`)'
local GET_USER_ID = 'SELECT `userId` FROM `users` WHERE `license2` = ? LIMIT 1'
local CREATE_SLOTS = 'INSERT IGNORE INTO `char_slots` (`userId`, `slots`) VALUES (?, ?)'
-- Database query used to register or update a user during login
---@param identifiers table
---@param maxCharacters number
---@return number | boolean
function db.userLogin(identifiers, maxCharacters)
    MySQL.prepare.await(UPSERT_USER, { identifiers.license, identifiers.license2, identifiers.fivem, identifiers.steam, identifiers.discord })

    local userId = MySQL.scalar.await(GET_USER_ID, { identifiers.license2 })

    if not userId then
        return false
    end

    MySQL.prepare.await(CREATE_SLOTS, { userId, maxCharacters })

    return userId
end

local GET_SLOTS = 'SELECT `slots` FROM `char_slots` WHERE `userId` = ? LIMIT 1'
-- Database query used to get user's character max slots
---@param userId number
---@return number | boolean slots
function db.getUserSlots(userId)
    local slots = MySQL.scalar.await(GET_SLOTS, { userId })

    if not slots then
        return false
    end

    return slots
end

local GET_CHARACTERS = 'SELECT `charId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? AND `slot` <= ? ORDER BY `slot` ASC'
-- Database query used to get user's character slots and all their characters
---@param userId number
---@return table characters
function db.getUserCharacters(userId, slots)
    local rows = MySQL.query.await(GET_CHARACTERS, { userId, slots }) or {}

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

local GET_CHARACTER_BY_SLOT = 'SELECT `charId`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? AND `slot` = ? LIMIT 1'
-- Database query used to get a character from a precise slot
---@param userId number
---@param slot number
---@return table character
function db.getCharacterBySlot(userId, slot)
    return MySQL.single.await(GET_CHARACTER_BY_SLOT, { userId, slot })
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

local GET_STATUS = 'SELECT `health`, `armor`, `hunger`, `thirst`, `stress` FROM `char_status` WHERE `charId` = ? LIMIT 1'
-- Database query used to get the status of a character
---@param charId number
---@return table | nil status
function db.getStatus(charId)
    return MySQL.single.await(GET_STATUS, { charId })
end

local SAVE_STATUS = 'INSERT INTO `char_status` (`charId`, `health`, `armor`, `hunger`, `thirst`, `stress`) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `health` = VALUES(`health`), `armor` = VALUES(`armor`), `hunger` = VALUES(`hunger`), `thirst` = VALUES(`thirst`), `stress` = VALUES(`stress`)'
-- Database query used to save the status of a character
---@param charId number
---@param data table
function db.saveStatus(charId, data)
    MySQL.prepare.await(SAVE_STATUS, { charId, data.health, data.armor, data.hunger, data.thirst, data.stress })
end

local GET_GROUPS = 'SELECT `slot`, `cat`, `name`, `grade`, `duty` FROM `char_groups` WHERE `charId` = ? ORDER BY `slot` ASC'
-- Database query used to get the groups of a character
---@param charId number
---@return table groups
function db.getGroups(charId)
    return MySQL.query.await(GET_GROUPS, { charId })
end

local SAVE_GROUP = 'INSERT INTO `char_groups` (`charId`, `slot`, `cat`, `name`, `grade`, `duty`) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `cat` = VALUES(`cat`), `name` = VALUES(`name`), `grade` = VALUES(`grade`), `duty` = VALUES(`duty`)'
-- Database query used to save a group of a character
---@param charId number
---@param slot number
---@param data table
function db.saveGroup(charId, slot, data)
    MySQL.prepare.await(SAVE_GROUP, { charId, slot, data.cat, data.name, data.grade, data.duty and 1 or 0 })
end

local DELETE_GROUP_SLOT = 'DELETE FROM `char_groups` WHERE `charId` = ? AND `slot` = ?'
function db.deleteGroupBySlot(charId, slot)
    MySQL.prepare.await(DELETE_GROUP_SLOT, { charId, slot })
end

local DELETE_GROUP = 'DELETE FROM `char_groups` WHERE `charId` = ? AND `name` = ?'
-- Database query used to delete a group of a character
---@param charId number
---@param name string
function db.deleteGroupByName(charId, name)
    MySQL.prepare.await(DELETE_GROUP, { charId, name })
end

local SET_GRADE = 'UPDATE `char_groups` SET `grade` = ? WHERE `charId` = ? AND `slot` = ?'
---@param charId number
---@param slot number
---@param grade number
function db.setGrade(charId, slot, grade)
    MySQL.prepare.await(SET_GRADE, { grade, charId, slot })
end

local SET_DUTY = 'UPDATE `char_groups` SET `duty` = ? WHERE `charId` = ? AND `slot` = ?'
function db.setDuty(charId, slot, duty)
    MySQL.prepare.await(SET_DUTY, { duty and 1 or 0, charId, slot })
end

local GET_MONEY = 'SELECT `money`, `bank`, `black_money` FROM `char_money` WHERE `charId` = ? LIMIT 1'
function db.getMoney(charId)
    return MySQL.single.await(GET_MONEY, { charId })
end

local SAVE_MONEY = 'INSERT INTO `char_money` (`charId`, `money`, `bank`, `black_money`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `money` = VALUES(`money`), `bank` = VALUES(`bank`), `black_money` = VALUES(`black_money`)'
function db.saveMoney(charId, data)
    MySQL.prepare.await(SAVE_MONEY, { charId, data.money, data.bank, data.black_money })
end

local GET_DOCS = 'SELECT `type`, `issued_at`, `expires_at` FROM `char_docs` WHERE `charId` = ?'
---@param charId number
---@return table docs
function db.getDocs(charId)
    local rows = MySQL.query.await(GET_DOCS, { charId }) or {}
    local result = {}
    for _, row in ipairs(rows) do
        result[row.type] = { issued_at = row.issued_at, expires_at = row.expires_at or nil }
    end

    return result
end

local SAVE_DOC = 'INSERT INTO `char_docs` (`charId`, `type`, `expires_at`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `expires_at` = VALUES(`expires_at`)'
---@param charId number
---@param docType string
---@param expiresAt string | osdate | nil
function db.addDoc(charId, docType, expiresAt)
    MySQL.prepare.await(SAVE_DOC, { charId, docType, expiresAt or nil })
end

local DELETE_DOC = 'DELETE FROM `char_docs` WHERE `charId` = ? AND `type` = ?'
---@param charId number
---@param docType string
function db.removeDoc(charId, docType)
    MySQL.prepare.await(DELETE_DOC, { charId, docType })
end

return db