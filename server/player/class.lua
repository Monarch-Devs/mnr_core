local db = require 'server.player.db'

local groupsCache = require 'server.groups.cache'

local moneyTypes = require 'config.moneyTypes'
local docsTypes = require 'config.docsTypes'
local statusTypes = require 'config.statusTypes'

local maxGroups = GetConvarInt('mnr:maxGroups', 2)

---@section LOCAL HELPER FUNCTIONS

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

---@section LOAD FUNCTIONS

local function _loadBio(source, userId, slot)
    local charId, bio = db.getCharacterBySlot(userId, slot)

    if not charId then
        return false
    end

    Player(source).state:set('bio', bio, true)

    return charId, bio
end

local function _loadMoney(charId)
    local money = db.getMoney(charId)

    if not money then
        return { money = moneyTypes.money.playerStarter, bank = moneyTypes.bank.playerStarter, black_money = moneyTypes.black_money.playerStarter }
    end

    return money
end

local function _loadGroups(charId)
    local data = db.getGroups(charId) or {}

    local groups = {}
    for i = 1, maxGroups do
        groups[i] = false
    end

    for _, group in ipairs(data) do
        if group.slot >= 1 and group.slot <= maxGroups then
            groups[group.slot] = { cat = group.cat, name = group.name, grade = group.grade, duty = group.duty == 1 }
        end
    end

    return groups
end

local function _loadDocs(charId)
    local data = db.getDocs(charId)
    local now = os.date('%Y-%m-%d %H:%M:%S')

    local docs = {}
    for name, document in pairs(data) do
        if document.expires_at and document.expires_at < now then
            db.removeDoc(charId, name)
        else
            docs[name] = document
        end
    end

    for name, document in pairs(docsTypes) do
        if not docs[name] and document.starter then
            local expiresAt = document.duration and os.date('%Y-%m-%d %H:%M:%S', os.time() + document.duration) or nil
            db.addDoc(charId, name, expiresAt)
            docs[name] = { issued_at = now, expires_at = expiresAt }
        end
    end

    return docs
end

local function _loadStatus(source, charId)
    local res = db.getStatus(charId)

    local status = {}
    for name, data in pairs(statusTypes) do
        status[name] = (res and res[name]) or data.default

        Player(source).state:set(name, status[name], true)
    end

    return status
end

local function _loadFlags(source, charId)
    local res = db.getFlags(charId)

    if not res then
        res = { dead = false, jail = false, cuff = false, anim = false }
    end

    for name, state in pairs(res) do
        Player(source).state:set(name, state, true)
    end

    return res
end

---@section SAVE FUNCTIONS

local function _saveMoney(charId, money)
    if not money then return end

    db.saveMoney(charId, money)
end

local function _saveGroups(charId, groups)
    if not groups then return end

    for i, group in ipairs(groups) do
        if type(group) == 'table' then
            db.saveGroup(charId, i, group)
        else
            db.deleteGroupBySlot(charId, i)
        end
    end
end

local function _saveStatus(charId, status)
    if not status then return end

    db.saveStatus(charId, status)
end

---@section CLASS

---@class MnrPlayer
local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

function MnrPlayer.new(userId, src)
    return setmetatable({ userId = userId, source = src }, MnrPlayer)
end

function MnrPlayer:loadChar(slot)
    local charId, bio = _loadBio(self.source, self.userId, slot)
    if not charId or not bio then
        return false, 'char_error'
    end

    self.charId = charId
    self.bio = bio
    self.money = _loadMoney(self.charId)
    self.groups = _loadGroups(self.charId)
    self.docs = _loadDocs(self.charId)
    self.flags = _loadFlags(self.source, self.charId)
    self.status = _loadStatus(self.source, self.charId)

    local payload = { charId = self.charId, bio = self.bio, money = self.money, groups = self.groups, docs = self.docs, status = self.status }
    TriggerClientEvent('mnr:client:OnCharacterLoaded', self.source, payload)
    TriggerEvent('mnr:server:OnCharacterLoaded', self.source, payload)

    return true
end

function MnrPlayer:saveChar()
    if not self.charId then
        return
    end

    _saveMoney(self.charId, self.money)
    _saveGroups(self.charId, self.groups)
    _saveStatus(self.charId, self.status)
end

function MnrPlayer:getMoney(moneyType)
    return self.money and self.money[moneyType] or 0
end

function MnrPlayer:setMoney(moneyType, amount, operator)
    if not self.money or not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then
        return false
    end

    if operator == '+' then
        self.money[moneyType] += amount
    elseif operator == '-' then
        if self.money[moneyType] < amount then
            return false
        end

        self.money[moneyType] -= amount
    else
        self.money[moneyType] = amount
    end

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

    TriggerClientEvent('mnr:client:DutyChanged', self.source, slot, duty)

    return true
end

---@section GROUP RELATED SECONDARY METHODS

function MnrPlayer:hasGroupPermission(name, permissions, action)
    local slot = _findByName(self.groups, name)
    if not slot then
        return false
    end

    local group = groupsCache.getGroup(name)
    if not group then
        return false
    end

    return group:hasPermission(permissions, self.groups[slot].grade, action)
end

function MnrPlayer:getGroupMoney(groupName, moneyType)
    local group = groupsCache.getGroup(groupName)

    return group and group:getMoney(moneyType) or 0
end

function MnrPlayer:setGroupMoney(groupName, moneyType, amount, action)
    if not self:hasGroupPermission(groupName, 'fundPerms', action) then
        return false
    end

    local group = groupsCache.getGroup(groupName)
    if not group then
        return false
    end

    local operator
    if action == 'deposit' then
        operator = '+'
    elseif action == 'withdraw' then
        operator = '-'
    else
        return false
    end

    return group and group:setMoney(moneyType, amount, operator)
end

---@section DOCS METHODS

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
        self.status[name] = lib.math.clamp(self.status[name] + value, statusTypes[name].min, statusTypes[name].max)
    elseif operator == '-' then
        self.status[name] = lib.math.clamp(self.status[name] - value, statusTypes[name].min, statusTypes[name].max)
    else
        self.status[name] = lib.math.clamp(value, statusTypes[name].min, statusTypes[name].max)
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