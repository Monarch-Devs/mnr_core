local db = require 'server.player.db'
local moneyTypes = require 'config.moneyTypes'

local MnrMoney = {}

function MnrMoney.load(charId)
    local row = db.getMoney(charId)

    return row or { money = moneyTypes.money.starter, bank = moneyTypes.bank.starter, black_money = moneyTypes.black_money.starter }
end

function MnrMoney.save(charId, data)
    if not data then
        return
    end

    db.saveMoney(charId, data)
end

---@param money table
---@param moneyType string
---@param amount number
---@param reason? string
---@return boolean
function MnrMoney.add(charId, money, moneyType, amount, reason)
    if not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        return false
    end

    money[moneyType] = money[moneyType] + amount

    db.saveMoney(charId, money)

    return true
end

---@param money table
---@param moneyType string
---@param amount number
---@param reason? string
---@return boolean
function MnrMoney.remove(charId, money, moneyType, amount, reason)
    if not moneyTypes[moneyType] then
        return false
    end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        return false
    end

    if money[moneyType] < amount then
        return false
    end

    money[moneyType] = money[moneyType] - amount
    db.saveMoney(charId, money)

    return true
end

return MnrMoney