local maxGroups = GetConvarInt('mnr:maxGroups', 2)
local db = require 'server.player.db'

local MnrGroups = {}

function MnrGroups.load(charId)
    local data = db.getGroups(charId)

    local slots = {}
    for i = 1, maxGroups do
        slots[i] = { cat = 'CIV', name = 'civilian', grade = 1, duty = false }
    end

    for _, group in ipairs(data) do
        if group.slot >= 1 and group.slot <= maxGroups then
            slots[group.slot] = { cat = group.cat, name = group.name, grade = group.grade, duty = group.duty == 1 }
        end
    end

    return slots
end

function MnrGroups.save(charId, data)
    if not data then
        return
    end

    for i, group in ipairs(data) do
        db.saveGroup(charId, i, group)
    end
end

-- Returns the first free slot index, or nil if full
---@param slots table
---@return number | nil
local function freeSlot(slots)
    for i, v in ipairs(slots) do
        if not v then
            return i
        end
    end
end

-- Returns the slot index of a group by name, or nil
---@param slots table
---@param name string
---@return number | nil
local function findByName(slots, name)
    for i, v in ipairs(slots) do
        if type(v) == 'table' and v.name == name then
            return i
        end
    end
end

---@param charId number
---@param groupList table
---@param slot number
---@param cat string
---@param name string
---@param grade number
---@return table | false, string | nil
function MnrGroups.set(charId, groupList, slot, cat, name, grade)
    if slot < 1 or slot > maxGroups then
        return false, 'invalid_slot'
    end

    if findByName(groupList, name) then
        return false, 'name_taken'
    end

    db.saveGroup(charId, slot, { cat = cat, name = name, grade = grade })

    groupList[slot] = { cat = cat, name = name, grade = grade }

    return groupList
end

---@param charId number
---@param groupList table
---@param cat string
---@param name string
---@param grade number
---@return table | false, string | nil
function MnrGroups.add(charId, groupList, cat, name, grade)
    if findByName(groupList, name) then
        return false, 'name_taken'
    end

    local slot = freeSlot(groupList)
    if not slot then
        return false, 'no_free_slot'
    end

    db.saveGroup(charId, slot, { cat = cat, name = name, grade = grade })

    groupList[slot] = { cat = cat, name = name, grade = grade }

    return groupList
end

---@param charId number
---@param groupList table
---@param slot number
---@return table | false, string | nil
function MnrGroups.removeBySlot(charId, groupList, slot)
    if not groupList[slot] then
        return false, 'slot_empty'
    end

    db.deleteGroupBySlot(charId, slot)

    groupList[slot] = false

    return groupList
end

---@param charId number
---@param groupList table
---@param name string
---@return table | false, string | nil
function MnrGroups.removeByName(charId, groupList, name)
    local slot = findByName(groupList, name)
    if not slot then
        return false, 'not_found'
    end

    db.deleteGroupByName(charId, name)

    groupList[slot] = false

    return groupList
end

---@param charId number
---@param groupList table
---@param slot number
---@param duty boolean
---@return table | false, string | nil
function MnrGroups.setDuty(charId, groupList, slot, duty)
    if not groupList[slot] then
        return false, 'slot_empty'
    end

    db.setDuty(charId, slot, duty)
    groupList[slot].duty = duty

    return groupList
end

return MnrGroups