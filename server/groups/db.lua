local db = {}

local GET_GROUPS_NAMES = 'SELECT `name` FROM `groups`'
-- Database function to get the names of groups saved in database
---@return table | false groupNames
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

local GET_GROUP_IS_USED = 'SELECT COUNT(*) FROM `char_groups` WHERE `name` = ?'
-- Database function to get the number of player that have the group
---@todo DELETION OF GROUPS NOT IN CONFIG FROM char_groups or DB FK and deprecate this
---@param name string
---@return number | false count
function db.getGroupIsUsed(name)
    local result = MySQL.scalar.await(GET_GROUP_IS_USED, { name })

    if not result then
        return false
    end

    return result
end

local DELETE_GROUP = 'DELETE FROM `groups` WHERE `name` = ?'
-- Database function to delete a group
---@param name string
---@todo --[[return boolean success]]
function db.deleteGroup(name)
    MySQL.prepare.await(DELETE_GROUP, { name })
end

local ADD_GROUP = 'INSERT INTO `groups` (`name`, `label`, `cat`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `cat` = VALUES(`cat`)'
-- Database function to add a group
---@param name string
---@param label string
---@param cat string
---@todo --[[return boolean success]]
function db.addGroup(name, label, cat)
    MySQL.prepare.await(ADD_GROUP, { name, label, cat })
end

local ADD_GRADE = 'INSERT INTO `group_grades` (`group_name`, `grade`, `label`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`)'
-- Database function to add a grade
---@param name string
---@param grade number
---@param label string
---@todo --[[return boolean success]]
function db.addGrade(name, grade, label)
    MySQL.prepare.await(ADD_GRADE, { name, grade, label })
end

return db