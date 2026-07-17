local groups = mnr.import('config/groups', 'lua', true)
local groupsCache = mnr.import('server/groups/cache', 'lua', true)
local playerCache = mnr.import('server/player/cache', 'lua', true)
local MnrGroup = mnr.import('server/groups/class', 'lua', true)
local db = mnr.import('server/groups/db', 'lua', true)

---@section Groups Cleanup (Needed for more scalability for a future manager/creator)

local function removeOrphanGroups(dbGroups)
    for name in pairs(dbGroups) do
        if not groups[name] then
            db.deleteGroup(name)
            print(('[mnr_core] Removed orphan group "%s" (cascade)'):format(name))
        end
    end
end

local function removeOrphanGrades()
    local minGradeByGroup = {}

    for name, group in pairs(groups) do
        db.addGroup(name, group.label, group.cat)
        db.addGrades(name, group.grades)

        local dbGrades = db.getGroupGrades(name) or {}
        local minGrade = math.maxinteger
        for level in pairs(group.grades) do
            if level < minGrade then
                minGrade = level
            end
        end

        minGradeByGroup[name] = minGrade ~= math.maxinteger and minGrade or 1

        for level in pairs(dbGrades) do
            if not group.grades[level] then
                db.deleteGrade(name, level)
                print(('[mnr_core] Removed orphan grade %d from "%s"'):format(level, name))
            end
        end
    end

    return minGradeByGroup
end

local function removeAssignedGrades(minGradeByGroup)
    for name, group in pairs(groups) do
        local minGrade = minGradeByGroup[name]
        local rows = db.getCharGroups(name) or {}
        for _, row in ipairs(rows) do
            if not group.grades[row.grade] then
                db.updateCharGroupGrade(row.charId, name, minGrade)
                print(('[mnr_core] FIXED charId %d group "%s": grade -> %d (MIN RESET)'):format(row.charId, name, minGrade))
            end
        end

        groupsCache.addGroup(name, MnrGroup.new(name, group.cat, { boss = group.boss, fund = group.fund }))
    end
end

local function groupsCleanup()
    local dbGroups = db.getGroupsNames()

    if dbGroups then
        removeOrphanGroups(dbGroups)
    end

    local minGradeByGroup = removeOrphanGrades()
    removeAssignedGrades(minGradeByGroup)

    print('[mnr_core] Groups cleanup completed')
end

CreateThread(groupsCleanup)

---@section Groups Actions

---@param source number
---@param groupName string
---@return MnrPlayer | nil, MnrGroup | nil, table | nil, string | nil
local function checkGroupAction(source, groupName)
    local caller = playerCache.getPlayer(source)
    if not caller then
        return nil, nil, nil, 'no_caller'
    end

    local group = groupsCache.getGroup(groupName)
    if not group then
        return nil, nil, nil, 'no_group'
    end

    local callerGroup = caller:getGroup(groupName)
    if not callerGroup then
        return nil, nil, nil, 'no_member'
    end

    return caller, group, callerGroup
end

---@param source number
---@param targetCharId number
---@param groupName string
---@param action 'hire' | 'fire' | 'promote'
---@param grade? number (Only promote)
---@return boolean success, string | nil error
mnr.rpc.handle('mnr_core:server:GroupBossAction', function(source, targetCharId, groupName, action, grade)
    local caller, group, callerGroup, err = checkGroupAction(source, groupName)
    if not caller or not group or not callerGroup then
        return false, err
    end

    if not group:hasPermission('boss', callerGroup.grade, action) then
        return false, 'no_perms'
    end

    local target = playerCache.getByCharId(targetCharId)
    if not target then
        return false, 'no_target'
    end

    local targetGroup, slot = target:getGroup(groupName)
    if targetGroup and targetGroup.grade >= callerGroup.grade then
        return false, 'no_allowed'
    end

    if grade and grade >= callerGroup.grade then
        return false, 'no_allowed'
    end

    if action == 'hire' then
        if targetGroup then
            return false, 'already_in_group'
        end

        local success, actionErr = target:addGroup(group.cat, groupName, grade)
        if not success then
            return false, actionErr
        end
    elseif action == 'fire' then
        if not targetGroup then
            return false, 'not_in_group'
        end

        local success, actionErr = target:removeGroup(slot)
        if not success then
            return false, actionErr
        end
    elseif action == 'promote' then
        if not targetGroup then
            return false, 'not_in_group'
        end

        local success, actionErr = target:setGrade(slot, grade)
        if not success then
            return false, actionErr
        end
    end

    return true, nil
end)

---@param source number
---@param groupName string
---@return table | false groupMoney, string | nil error
mnr.rpc.handle('mnr_core:server:GroupFundView', function(source, groupName)
    local caller, group, callerGroup, err = checkGroupAction(source, groupName)
    if not caller or not group or not callerGroup then
        return false, err
    end

    if not group:hasPermission('fund', callerGroup.grade, 'view') then
        return false, 'no_perms'
    end

    return group.money, nil
end)

---@param source number
---@param groupName string
---@param action 'deposit' | 'withdraw'
---@return boolean success, string | nil error
mnr.rpc.handle('mnr_core:server:GroupFundAction', function(source, groupName, action, amount, account)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return false, 'invalid_amount'
    end

    local caller, group, callerGroup, err = checkGroupAction(source, groupName)
    if not caller or not group or not callerGroup then
        return false, err
    end

    if not group:hasPermission('fund', callerGroup.grade, action) then
        return false, 'no_perms'
    end

    if action == 'deposit' and caller.money[account] < amount then
        return false, 'not_enough'
    end

    if action == 'withdraw' and group.money[account] < amount then
        return false, 'not_enough'
    end

    caller:setMoney(account, amount, action == 'deposit' and '-' or '+')
    group:setMoney(account, amount, action == 'deposit' and '+' or '-')

    return true, nil
end)

---@section Resource Stop

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end

    for _, group in pairs(groupsCache.getAllGroups()) do
        group:saveMoney()
    end
end)

---@section Exports

exports('GetGroupMoney', function(name, moneyType)
    local group = groupsCache.getGroup(name)

    return group and group:getMoney(moneyType) or 0
end)

exports('SetGroupMoney', function(name, moneyType, amount, operator)
    local group = groupsCache.getGroup(name)

    return group and group:setMoney(moneyType, amount, operator) or false
end)