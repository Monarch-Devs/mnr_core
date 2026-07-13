---@class PlayerDB
local db = {}

local UPSERT_USER = 'INSERT INTO `users` (`license`, `license2`, `fivem`, `steam`, `discord`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `license` = COALESCE(VALUES(`license`), `license`), `fivem` = COALESCE(VALUES(`fivem`), `fivem`), `steam` = COALESCE(VALUES(`steam`), `steam`), `discord` = COALESCE(VALUES(`discord`), `discord`)'
local GET_USER_ID = 'SELECT `userId` FROM `users` WHERE `license2` = ? LIMIT 1'
local CREATE_SLOTS = 'INSERT IGNORE INTO `char_slots` (`userId`, `slots`) VALUES (?, ?)'
function db.userLogin(identifiers, maxCharacters)
    mnr_sql.prepare(UPSERT_USER, { identifiers.license, identifiers.license2, identifiers.fivem, identifiers.steam, identifiers.discord })

    local userId = mnr_sql.scalar(GET_USER_ID, { identifiers.license2 })

    if not userId then
        return false
    end

    mnr_sql.prepare(CREATE_SLOTS, { userId, maxCharacters })

    return userId
end

local GET_SLOTS = 'SELECT `slots` FROM `char_slots` WHERE `userId` = ? LIMIT 1'
function db.getUserSlots(userId)
    local slots = mnr_sql.scalar(GET_SLOTS, { userId })

    if not slots then
        return false
    end

    return slots
end

local GET_CHARACTERS = 'SELECT `charId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? AND `slot` <= ? ORDER BY `slot` ASC'
function db.getUserCharacters(userId, slots)
    local rows = mnr_sql.query(GET_CHARACTERS, { userId, slots }) or {}

    local characters = {}
    for i = 1, slots do
        characters[i] = false
    end

    for _, row in ipairs(rows) do
        characters[row.slot] = { charId = row.charId, firstname = row.firstname, lastname = row.lastname, gender = row.gender, origin = row.origin, birthdate = row.birthdate / 1000 }
    end

    return characters
end

local GET_CHARACTER = 'SELECT `charId`, `firstname`, `lastname`, `gender`, `origin`, `birthdate` FROM `characters` WHERE `userId` = ? AND `slot` = ? LIMIT 1'
function db.getCharacter(userId, slot)
    local res = mnr_sql.single(GET_CHARACTER, { userId, slot })

    if not res then
        return false, false
    end

    return res.charId, { firstname = res.firstname, lastname = res.lastname, gender = res.gender, origin = res.origin, birthdate = res.birthdate / 1000 }
end

local ADD_CHARACTER = 'INSERT INTO `characters` (`userId`, `slot`, `firstname`, `lastname`, `gender`, `origin`, `birthdate`) VALUES (?, ?, ?, ?, ?, ?, ?)'
function db.addCharacter(userId, slot, char)
    local charId = mnr_sql.prepare(ADD_CHARACTER, { userId, slot, char.firstname, char.lastname, char.gender, char.origin, os.date('%Y-%m-%d', char.birthdate) })

    return charId
end

local GET_FLAGS = 'SELECT `dead`, `jail`, `cuff`, `anim` FROM `char_flags` WHERE `charId` = ? LIMIT 1'
function db.getFlags(charId)
    local res = mnr_sql.single(GET_FLAGS, { charId })

    if not res then
        return false
    end

    for name, state in pairs(res) do
        res[name] = state == 1
    end

    return res
end

local SAVE_FLAGS = 'INSERT INTO `char_flags` (`charId`, `dead`, `jail`, `cuff`, `anim`) VALUES (:charId, :dead, :jail, :cuff, :anim) ON DUPLICATE KEY UPDATE `dead` = :dead, `jail` = :jail, `cuff` = :cuff, `anim` = :anim'
function db.saveFlags(charId, flags)
    if not flags then return end

    local data = {
        charId = charId,
        dead = flags.dead and 1 or 0,
        jail = flags.jail and 1 or 0,
        cuff = flags.cuff and 1 or 0,
        anim = flags.anim and 1 or 0,
    }

    mnr_sql.prepare(SAVE_FLAGS, data)
end

local GET_STATUS = 'SELECT `health`, `armour`, `hunger`, `thirst`, `stress` FROM `char_status` WHERE `charId` = ? LIMIT 1'
function db.getStatus(charId)
    return mnr_sql.single(GET_STATUS, { charId })
end

local SAVE_STATUS = 'INSERT INTO `char_status` (`charId`, `health`, `armour`, `hunger`, `thirst`, `stress`) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `health` = VALUES(`health`), `armour` = VALUES(`armour`), `hunger` = VALUES(`hunger`), `thirst` = VALUES(`thirst`), `stress` = VALUES(`stress`)'
function db.saveStatus(charId, data)
    mnr_sql.prepare(SAVE_STATUS, { charId, data.health, data.armour, data.hunger, data.thirst, data.stress })
end

local GET_GROUPS = 'SELECT `slot`, `cat`, `name`, `grade`, `duty` FROM `char_groups` WHERE `charId` = ? ORDER BY `slot` ASC'
function db.getGroups(charId)
    return mnr_sql.query(GET_GROUPS, { charId })
end

local SAVE_GROUP = 'INSERT INTO `char_groups` (`charId`, `slot`, `cat`, `name`, `grade`, `duty`) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `cat` = VALUES(`cat`), `name` = VALUES(`name`), `grade` = VALUES(`grade`), `duty` = VALUES(`duty`)'
function db.saveGroup(charId, slot, data)
    mnr_sql.prepare(SAVE_GROUP, { charId, slot, data.cat, data.name, data.grade, data.duty and 1 or 0 })
end

local DELETE_GROUP_SLOT = 'DELETE FROM `char_groups` WHERE `charId` = ? AND `slot` = ?'
function db.deleteGroupBySlot(charId, slot)
    mnr_sql.prepare(DELETE_GROUP_SLOT, { charId, slot })
end

local DELETE_GROUP = 'DELETE FROM `char_groups` WHERE `charId` = ? AND `name` = ?'
function db.deleteGroupByName(charId, name)
    mnr_sql.prepare(DELETE_GROUP, { charId, name })
end

local SET_GRADE = 'UPDATE `char_groups` SET `grade` = ? WHERE `charId` = ? AND `slot` = ?'
function db.setGrade(charId, slot, grade)
    mnr_sql.prepare(SET_GRADE, { grade, charId, slot })
end

local SET_DUTY = 'UPDATE `char_groups` SET `duty` = ? WHERE `charId` = ? AND `slot` = ?'
function db.setDuty(charId, slot, duty)
    mnr_sql.prepare(SET_DUTY, { duty and 1 or 0, charId, slot })
end

local GET_MONEY = 'SELECT `money`, `bank`, `black_money` FROM `char_money` WHERE `charId` = ? LIMIT 1'
function db.getMoney(charId)
    return mnr_sql.single(GET_MONEY, { charId })
end

local SAVE_MONEY = 'INSERT INTO `char_money` (`charId`, `money`, `bank`, `black_money`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `money` = VALUES(`money`), `bank` = VALUES(`bank`), `black_money` = VALUES(`black_money`)'
function db.saveMoney(charId, data)
    mnr_sql.prepare(SAVE_MONEY, { charId, data.money, data.bank, data.black_money })
end

local GET_DOCS = 'SELECT `type`, `issued`, `expiry` FROM `char_docs` WHERE `charId` = ?'
function db.getDocs(charId)
    local rows = mnr_sql.query(GET_DOCS, { charId }) or {}
    local result = {}
    for _, row in ipairs(rows) do
        result[row.type] = { issued = row.issued / 1000, expiry = row.expiry and (row.expiry / 1000) or nil }
    end

    return result
end

local SAVE_DOC = 'INSERT INTO `char_docs` (`charId`, `type`, `issued`, `expiry`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `expiry` = VALUES(`expiry`)'
function db.addDoc(charId, docType, issued, expiry)
    mnr_sql.prepare(SAVE_DOC, { charId, docType, os.date('%Y-%m-%d', issued), expiry and os.date('%Y-%m-%d', expiry) or nil })
end

local DELETE_DOC = 'DELETE FROM `char_docs` WHERE `charId` = ? AND `type` = ?'
function db.removeDoc(charId, docType)
    mnr_sql.prepare(DELETE_DOC, { charId, docType })
end

return db