local db = require 'server.player.db'
local moneyTypes = require 'config.moneyTypes'

local maxGroups = GetConvarInt('mnr:maxGroups', 2)

---@description [SECTION] LOCAL FUNCTIONS

---@return number | nil
local function _freeSlot(groups)
    for i, v in ipairs(groups) do
        if not v then return i end
    end
end

---@param name string
---@return number | nil
local function _findByName(groups, name)
    for i, v in ipairs(groups) do
        if type(v) == 'table' and v.name == name then return i end
    end
end

local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

---@param userId number
---@param src number
---@return MnrPlayer
function MnrPlayer.new(userId, src)
    return setmetatable({ userId = userId, source = src }, MnrPlayer)
end

---@return number
function MnrPlayer:getSource()
    return self.source
end

---@description [SECTION] MONEY FUNCTIONS

function MnrPlayer:_loadMoney()
    local row = db.getMoney(self.charId)
    self.money = row or {
        money = moneyTypes.money.starter,
        bank = moneyTypes.bank.starter,
        black_money = moneyTypes.black_money.starter,
    }
end

function MnrPlayer:_saveMoney()
    if not self.money then return end

    db.saveMoney(self.charId, self.money)
end

---@description [SECTION] GROUPS FUNCTIONS

function MnrPlayer:_loadGroups()
    local data = db.getGroups(self.charId)

    self.groups = {}
    for i = 1, maxGroups do
        self.groups[i] = false
    end

    for _, group in ipairs(data) do
        if group.slot >= 1 and group.slot <= maxGroups then
            self.groups[group.slot] = {
                cat = group.cat,
                name = group.name,
                grade = group.grade,
                duty = group.duty == 1,
            }
        end
    end
end

function MnrPlayer:_saveGroups()
    if not self.groups then return end

    db.deleteAllGroups(self.charId)

    for i, group in ipairs(self.groups) do
        if type(group) == 'table' then
            db.saveGroup(self.charId, i, group)
        end
    end
end

---@description [SECTION] STATUS FUNCTIONS

function MnrPlayer:_loadStatus()
    self.status = db.getStatus(self.charId) or {
        health = 200,
        armor = 0,
        hunger = 100,
        thirst = 100,
        stress = 0,
    }
end

function MnrPlayer:_saveStatus()
    if not self.status then
        return
    end

    db.saveStatus(self.charId, self.status)
end

---@param data table
function MnrPlayer:loadChar(data)
    self.charId = data.charId

    self.bio = {
        firstname = data.firstname,
        lastname  = data.lastname,
        gender    = data.gender,
        origin    = data.origin,
        birthdate = data.birthdate,
    }

    self:_loadMoney()
    self:_loadGroups()
    self:_loadStatus()
end

function MnrPlayer:save()
    if not self.charId then
        return
    end

    self:_saveMoney()
    self:_saveGroups()
    self:_saveStatus()
end

---@param moneyType string
---@return number
function MnrPlayer:getMoney(moneyType)
    return self.money and self.money[moneyType] or 0
end

---@param moneyType string
---@param amount number
---@return boolean
function MnrPlayer:addMoney(moneyType, amount)
    if not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false
    end

    self.money[moneyType] += amount
    db.saveMoney(self.charId, self.money)

    return true
end

---@param moneyType string
---@param amount number
---@return boolean
function MnrPlayer:removeMoney(moneyType, amount)
    if not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false
    end

    if self.money[moneyType] < amount then
        return false
    end

    self.money[moneyType] -= amount
    db.saveMoney(self.charId, self.money)

    return true
end

---@param cat string
---@param name string
---@param grade number
---@return boolean, string | nil
function MnrPlayer:addGroup(cat, name, grade)
    if _findByName(self.groups, name) then
        return false, 'name_taken'
    end

    local slot = _freeSlot(self.groups)
    if not slot then
        return false, 'no_free_slot'
    end

    db.saveGroup(self.charId, slot, { cat = cat, name = name, grade = grade })
    self.groups[slot] = { cat = cat, name = name, grade = grade }

    return true
end

---@param slot number
---@param cat string
---@param name string
---@param grade number
---@return boolean, string | nil
function MnrPlayer:setGroup(slot, cat, name, grade)
    if slot < 1 or slot > maxGroups then
        return false, 'invalid_slot'
    end

    if _findByName(self.groups, name) then
        return false, 'name_taken'
    end

    db.saveGroup(self.charId, slot, { cat = cat, name = name, grade = grade })
    self.groups[slot] = { cat = cat, name = name, grade = grade }

    return true
end

---@param name string
---@return table | nil, number | nil
function MnrPlayer:getGroup(name)
    local slot = _findByName(self.groups, name)

    if not slot then
        return nil
    end

    return self.groups[slot], slot
end

---@param cat string
---@return table
function MnrPlayer:getGroupsByCategory(cat)
    local result = {}
    for slot, group in ipairs(self.groups) do
        if type(group) == 'table' and group.cat == cat then
            result[#result + 1] = { slot = slot, group = group }
        end
    end

    return result
end

---@param slot number
---@return boolean, string | nil
function MnrPlayer:removeGroup(slot)
    if not self.groups[slot] then
        return false, 'slot_empty'
    end

    db.deleteGroupBySlot(self.charId, slot)
    self.groups[slot] = false

    return true
end

---@param slot number
---@param duty boolean
---@return boolean, string | nil
function MnrPlayer:setDuty(slot, duty)
    if not self.groups[slot] then
        return false, 'slot_empty'
    end

    db.setDuty(self.charId, slot, duty)
    self.groups[slot].duty = duty

    TriggerClientEvent('mnr:client:DutyChanged', self:getSource(), slot, duty)

    return true
end

return MnrPlayer