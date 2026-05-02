local db = {}

local GET_GROUPS_NAMES = 'SELECT `name` FROM `groups`'
-- Database function to get a groups map for cleanup
---@return table<string, true> | false
function db.getGroupsNames()
    local result = MySQL.query.await(GET_GROUPS_NAMES)

    if not result then
        return false
    end

    local groupNames = {}
    for _, row in ipairs(result) do
        groupNames[row.name] = true
    end

    return groupNames
end

local ADD_GROUP = 'INSERT INTO `groups` (`name`, `label`, `cat`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `cat` = VALUES(`cat`)'
-- Database function to update a group
---@param name string
---@param label string
---@param cat string
function db.addGroup(name, label, cat)
    MySQL.prepare.await(ADD_GROUP, { name, label, cat })
end

local DELETE_GROUP = 'DELETE FROM `groups` WHERE `name` = ?'
-- Database function to delete an unused group
---@param name string
function db.deleteGroup(name)
    MySQL.prepare.await(DELETE_GROUP, { name })
end

local GET_GROUP_GRADES = 'SELECT `grade` FROM `group_grades` WHERE `group_name` = ?'
-- Database function to get a grades map for cleanup
---@param name string
---@return table<number, true> | false
function db.getGroupGrades(name)
    local result = MySQL.query.await(GET_GROUP_GRADES, { name })
    if not result then
        return false
    end

    local grades = {}
    for _, row in ipairs(result) do
        grades[row.grade] = true
    end

    return grades
end

local ADD_GRADES = 'INSERT INTO `group_grades` (`group_name`, `grade`, `label`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`)'
-- Database function to update grades
---@param name string
---@param grades table
function db.addGrades(name, grades)
    local queries = {}

    for level, grade in pairs(grades) do
        queries[#queries + 1] = { query = ADD_GRADES, values = { name, level, grade.label } }
    end

    MySQL.transaction.await(queries)
end

local DELETE_GRADE = 'DELETE FROM `group_grades` WHERE `group_name` = ? AND `grade` = ?'
-- Database function to delete a grade
---@param name string
---@param grade number
function db.deleteGrade(name, grade)
    MySQL.prepare.await(DELETE_GRADE, { name, grade })
end

local GET_CHAR_GROUPS = 'SELECT `charId`, `grade` FROM `char_groups` WHERE `name` = ?'
-- Database function to get char groups
---@param name string
---@return { charId: number, grade: number }[] | nil
function db.getCharGroups(name)
    return MySQL.query.await(GET_CHAR_GROUPS, { name })
end

local UPDATE_CHAR_GROUP_GRADE = 'UPDATE `char_groups` SET `grade` = ? WHERE `charId` = ? AND `name` = ?'
-- Database function to fix char groups grade
---@param charId number
---@param name string
---@param grade number
function db.updateCharGroupGrade(charId, name, grade)
    MySQL.prepare.await(UPDATE_CHAR_GROUP_GRADE, { grade, charId, name })
end

return db