local db = require 'server.player.db'
local moneyTypes = require 'config.moneyTypes'
local docsTypes = require 'config.docsTypes'
local statusTypes = require 'config.statusTypes'

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

---@class MnrPlayer
local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

function MnrPlayer.new(userId, src)
    return setmetatable({ userId = userId, source = src }, MnrPlayer)
end

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
    local data = db.getGroups(self.charId) or {}

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

    for i, group in ipairs(self.groups) do
        if type(group) == 'table' then
            db.saveGroup(self.charId, i, group)
        else
            db.deleteGroupBySlot(self.charId, i)
        end
    end
end

---@section DOCS LOAD/SAVE FUNCTIONS

function MnrPlayer:_loadDocs()
    local data = db.getDocs(self.charId)
    local now = os.date('%Y-%m-%d %H:%M:%S')
    self.docs = {}

    for docType, doc in pairs(data) do
        if doc.expires_at and doc.expires_at < now then
            db.removeDoc(self.charId, docType)
        else
            self.docs[docType] = doc
        end
    end

    for docType, docData in pairs(docsTypes) do
        if not self.docs[docType] and docData.starter then
            local expiresAt = docData.duration and os.date('%Y-%m-%d %H:%M:%S', os.time() + docData.duration) or nil
            db.addDoc(self.charId, docType, expiresAt)
            self.docs[docType] = { issued_at = now, expires_at = expiresAt }
        end
    end
end

---@section STATUS LOAD/SAVE FUNCTIONS

function MnrPlayer:_loadStatus()
    local data = db.getStatus(self.charId)

    self.status = {}

    for name, status in pairs(statusTypes) do
        if not data then
            self.status[name] = status.default
        else
            self.status[name] = data[name] and data[name] or status.default
        end

        Player(self.source).state:set(name, self.status[name], true)
    end
end

function MnrPlayer:_saveStatus()
    if not self.status then
        return
    end

    db.saveStatus(self.charId, self.status)
end

function MnrPlayer:loadChar(data)
    self.charId = data.charId

    self.bio = {
        firstname = data.firstname,
        lastname = data.lastname,
        gender = data.gender,
        origin = data.origin,
        birthdate = data.birthdate,
    }

    self:_loadMoney()
    self:_loadGroups()
    self:_loadDocs()
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

function MnrPlayer:getMoney(moneyType)
    return self.money and self.money[moneyType] or 0
end

function MnrPlayer:addMoney(moneyType, amount)
    if not self.money or not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false
    end

    self.money[moneyType] += amount

    return true
end

function MnrPlayer:removeMoney(moneyType, amount)
    if not self.money or not moneyTypes[moneyType] then
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

    return true
end

function MnrPlayer:addGroup(cat, name, grade)
    if _findByName(self.groups, name) then
        return false, 'name_taken'
    end

    local slot = _freeSlot(self.groups)
    if not slot then
        return false, 'no_free_slot'
    end

    db.saveGroup(self.charId, slot, { cat = cat, name = name, grade = grade, duty = false })
    self.groups[slot] = { cat = cat, name = name, grade = grade, duty = false }

    return true
end

function MnrPlayer:setGroup(slot, cat, name, grade)
    if slot < 1 or slot > maxGroups then
        return false, 'invalid_slot'
    end

    if _findByName(self.groups, name) then
        return false, 'name_taken'
    end

    db.saveGroup(self.charId, slot, { cat = cat, name = name, grade = grade, duty = false })
    self.groups[slot] = { cat = cat, name = name, grade = grade, duty = false }

    return true
end

function MnrPlayer:getGroup(name)
    local slot = _findByName(self.groups, name)

    if not slot then
        return false
    end

    return self.groups[slot], slot
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
    if not self.groups[slot] then
        return false, 'slot_empty'
    end

    db.deleteGroupBySlot(self.charId, slot)
    self.groups[slot] = false

    return true
end

function MnrPlayer:setGrade(slot, grade)
    if not self.groups[slot] then
        return false, 'slot_empty'
    end

    if type(grade) ~= 'number' or grade < 1 then
        return false, 'invalid_grade'
    end

    db.setGrade(self.charId, slot, grade)
    self.groups[slot].grade = grade

    return true
end

function MnrPlayer:setDuty(slot, duty)
    if not self.groups[slot] then
        return false, 'slot_empty'
    end

    db.setDuty(self.charId, slot, duty)
    self.groups[slot].duty = duty

    TriggerClientEvent('mnr:client:DutyChanged', self:getSource(), slot, duty)

    return true
end

function MnrPlayer:addDoc(docType, expiresAt)
    db.addDoc(self.charId, docType, expiresAt)
    self.docs[docType] = { issued_at = os.date('%Y-%m-%d %H:%M:%S'), expires_at = expiresAt }
    return true
end

function MnrPlayer:removeDoc(docType)
    if not self.docs or not self.docs[docType] then
        return false, 'not_found'
    end

    db.removeDoc(self.charId, docType)
    self.docs[docType] = nil

    return true
end

function MnrPlayer:hasDoc(docType)
    if not self.docs or not self.docs[docType] then
        return false
    end

    local doc = self.docs[docType]
    if doc.expires_at and doc.expires_at < os.date('%Y-%m-%d %H:%M:%S') then
        db.removeDoc(self.charId, docType)
        self.docs[docType] = nil

        return false
    end

    return true
end

function MnrPlayer:setStatus(name, value, operator)
    if not self.status[name] or not value or type(value) ~= 'number' then
        return false
    end

    if operator == '+' then
        self.status[name] += value
    elseif operator == '-' then
        self.status[name] -= value
    else
        self.status[name] = value
    end

    Player(self.source).state:set(name, self.status[name], true)
end

function MnrPlayer:degradeStatus()
    for name, status in pairs(statusTypes) do
        if not status.degrade then goto skip_status end

        self.status[name] = lib.math.clamp(self.status[name] - status.degrade, status.min, status.max)
        Player(self.source).state:set(name, self.status[name], true)

        ::skip_status::
    end
end

return MnrPlayer