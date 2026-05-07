-- server/groups/class.lua
local moneyTypes = require 'config.moneyTypes'
local db = require 'server.groups.db'

---@param name string
---@return table
---@todo Group not hardcoded loading using moneyTypes
local function loadGroupMoney(name)
    local row = db.getFunds(name)

    return row or { money = 0, bank = 0, black_money = 0 }
end

---@class MnrGroup
local MnrGroup = {}
MnrGroup.__index = MnrGroup

---@param name string
---@param cat string
---@param perms { bossPerms: table<number, table<string, boolean>>, fundPerms: table<number, table<string, boolean>> }
function MnrGroup.new(name, cat, perms)
    return setmetatable({
        name = name,
        cat = cat,
        duty = {},
        online = {},
        offline = {},
        bossPerms = perms.bossPerms or {},
        fundPerms = perms.fundPerms or {},
        money = loadGroupMoney(name),
    }, MnrGroup)
end

function MnrGroup:saveMoney()
    if not self.money then return end
    db.saveFunds(self.name, self.money)
end

---@param moneyType string
---@return number
function MnrGroup:getMoney(moneyType)
    return self.money and self.money[moneyType] or 0
end

---@param moneyType string
---@param amount number
---@return boolean
function MnrGroup:addMoney(moneyType, amount)
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

---@param moneyType string
---@param amount number
---@return boolean
function MnrGroup:removeMoney(moneyType, amount)
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

---@param permission 'bossPerms' | 'fundPerms'
---@param grade number
---@param action string
---@return boolean
function MnrGroup:hasPermission(permission, grade, action)
    local entry = self[permission][grade]

    return entry ~= nil and entry[action] == true
end

return MnrGroup