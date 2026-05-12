local moneyTypes = require 'config.moneyTypes'
local db = require 'server.groups.db'

---@param name string
---@return table
local function loadGroupMoney(name)
    local row = db.getFunds(name)
    if row then
        return row
    end

    return {
        money = moneyTypes.money.groupStarter,
        bank = moneyTypes.bank.groupStarter,
        black_money = moneyTypes.black_money.groupStarter
    }
end

---@class MnrGroup
local MnrGroup = {}
MnrGroup.__index = MnrGroup

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

function MnrGroup:getMoney(moneyType)
    return self.money and self.money[moneyType] or 0
end

function MnrGroup:setMoney(moneyType, amount, operator)
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

function MnrGroup:hasPermission(permission, grade, action)
    local entry = self[permission][grade]

    return entry ~= nil and entry[action] == true
end

return MnrGroup