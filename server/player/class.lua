---@class MnrPlayer
---@field userId number

local status = require 'server.player.status'
local groups = require 'server.player.groups'

local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

-- Constructor function
---@param userId number User ID retrieved from database
function MnrPlayer.new(userId)
    return setmetatable({ userId = userId }, MnrPlayer)
end

-- Class expansion function (Biography)
---@param data table Data of the character selected
function MnrPlayer:loadChar(data)
    self.charId = data.charId

    self.bio = {
        firstname = data.firstname,
        lastname = data.lastname,
        gender = data.gender,
        origin = data.origin,
        birthdate = data.birthdate,
    }

    self.status = status.load(self.charId)
    self.groups = groups.load(self.charId)
end

function MnrPlayer:addGroup(cat, name, grade)
    local result, err = groups.add(self.charId, self.groups, cat, name, grade)
    if not result then
        return false, err
    end

    self.groups = result

    return true
end

function MnrPlayer:setGroup(slot, cat, name, grade)
    local result, err = groups.set(self.charId, self.groups, slot, cat, name, grade)
    if not result then
        return false, err
    end

    self.groups = result

    return true
end

function MnrPlayer:getGroup(name)
    for slot, group in ipairs(self.groups) do
        if type(group) == 'table' and group.name == name then
            return group, slot
        end
    end

    return nil
end

function MnrPlayer:getGroupsByCategory(cat)
    local result = {}

    for slot, group in ipairs(self.groups) do
        if type(group) == 'table' and group.cat == cat then
            result[#result + 1] = { slot = slot, group = group }
        end
    end

    return result
end

function MnrPlayer:removeGroup(slot)
    local result, err = groups.removeBySlot(self.charId, self.groups, slot)
    if not result then
        return false, err
    end

    self.groups = result

    return true
end

---@param slot number
---@param duty boolean
function MnrPlayer:setDuty(slot, duty)
    local result, err = groups.setDuty(self.charId, self.groups, slot, duty)
    if not result then
        return false, err
    end

    self.groups = result

    TriggerClientEvent('mnr_core:client:DutyChanged', self:getSource(), slot, duty)

    return true
end

function MnrPlayer:save()
    if not self.charId then return end

    status.save(self.charId, self.status)
    groups.save(self.charId, self.groups)
end

return MnrPlayer