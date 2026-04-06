local MnrMoney = require 'server.player.money'
local MnrStatus = require 'server.player.status'
local MnrGroups = require 'server.player.groups'

local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

-- Constructor function
---@param userId number User ID retrieved from database
function MnrPlayer.new(userId, src)
    return setmetatable({ userId = userId, source = src }, MnrPlayer)
end

-- Function to get the source of the player
---@return number source The source of the player
function MnrPlayer:getSource()
    return self.source
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

    self.money = MnrMoney.load(self.charId)
    self.groups = MnrGroups.load(self.charId)
    self.status = MnrStatus.load(self.charId)
end

function MnrPlayer:addGroup(cat, name, grade)
    local result, err = MnrGroups.add(self.charId, self.groups, cat, name, grade)
    if not result then
        return false, err
    end

    self.groups = result

    return true
end

function MnrPlayer:setGroup(slot, cat, name, grade)
    local result, err = MnrGroups.set(self.charId, self.groups, slot, cat, name, grade)
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
    local result, err = MnrGroups.removeBySlot(self.charId, self.groups, slot)
    if not result then
        return false, err
    end

    self.groups = result

    return true
end

---@param slot number
---@param duty boolean
function MnrPlayer:setDuty(slot, duty)
    local result, err = MnrGroups.setDuty(self.charId, self.groups, slot, duty)
    if not result then
        return false, err
    end

    self.groups = result

    TriggerClientEvent('mnr_core:client:DutyChanged', self:getSource(), slot, duty)

    return true
end

function MnrPlayer:save()
    if not self.charId then return end

    MnrMoney.save(self.charId, self.money)
    MnrGroups.save(self.charId, self.groups)
    MnrStatus.save(self.charId, self.status)
end

function MnrPlayer:getMoney(moneyType)
    if not self.money then
        return 0
    end

    return self.money[moneyType] or 0
end

function MnrPlayer:addMoney(moneyType, amount, reason)
    return MnrMoney.add(self.charId, self.money, moneyType, amount, reason)
end

function MnrPlayer:removeMoney(moneyType, amount, reason)
    return MnrMoney.remove(self.charId, self.money, moneyType, amount, reason)
end

return MnrPlayer