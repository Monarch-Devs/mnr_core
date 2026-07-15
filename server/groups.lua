local groups = mnr.import('config/groups', 'lua', true)
local groupsCache = mnr.import('server/groups/cache', 'lua', true)
local playerCache = mnr.import('server/player/cache', 'lua', true)
local MnrGroup = mnr.import('server/groups/class', 'lua', true)
local db = mnr.import('server/groups/db', 'lua', true)

local function dbGroupsCleanup()
    local dbGroups = db.getGroupsNames()

    if dbGroups then
        for name in pairs(dbGroups) do
            if groups[name] then goto skip_group end

            db.deleteGroup(name)
            print(('[mnr_core] Removed orphan group "%s" (cascade)'):format(name))

            ::skip_group::
        end
    end

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
            if group.grades[level] then goto skip_grade end

            db.deleteGrade(name, level)
            print(('[mnr_core] Removed orphan grade %d from "%s"'):format(level, name))

            ::skip_grade::
        end
    end

    for name, group in pairs(groups) do
        local minGrade = minGradeByGroup[name]
        local rows = db.getCharGroups(name) or {}

        for _, row in ipairs(rows) do
            if group.grades[row.grade] then goto skip_char_grade end

            db.updateCharGroupGrade(row.charId, name, minGrade)
            print(('[mnr_core] FIXED char %d group "%s": grade -> %d (MIN RESET)'):format(row.charId, name, minGrade))

            ::skip_char_grade::
        end

        groupsCache.addGroup(name, MnrGroup.new(name, group.cat, { boss = group.boss, fund = group.fund }))
    end

    print('[mnr_core] Groups cleanup completed')
end

CreateThread(dbGroupsCleanup)

---@section Groups Actions

---@param caller MnrPlayer
---@param group MnrGroup
---@param callerGroup table
---@param perms 'boss' | 'fund'
---@param action 'hire' | 'fire' | 'promote' | 'view' | 'deposit' | 'withdraw'
---@return boolean success, string | nil error
local function actionCheck(caller, group, callerGroup, perms, action)
    if not caller then
        return false, 'no_caller'
    end

    if not group then
        return false, 'no_group'
    end

    if not group:hasPermission(perms, callerGroup.grade, action) then
        return false, 'no_perms'
    end

    return true, nil
end

---@param source number
---@param targetCharId number
---@param groupName string
---@param action 'hire' | 'fire' | 'promote'
---@param grade? number (Only promote)
---@return boolean success, string | nil error
mnr.rpc.handle('mnr_core:server:GroupBossAction', function(source, targetCharId, groupName, action, grade)
    local caller = playerCache.getPlayer(source)
    local group = groupsCache:getGroup(groupName)
    local callerGroup = caller:getGroup(groupName)

    local success, err = actionCheck(caller, group, callerGroup, 'boss', action)
    if not success then
        return false, err
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
        target:addGroup(group.cat, groupName, grade)
    elseif action == 'fire' then
        target:removeGroup(slot)
    elseif action == 'promote' then
        if not targetGroup then
            return false, 'not_in_group'
        end

        target:setGrade(slot, grade)
    end

    return true, nil
end)

---@param source number
---@param groupName string
---@return table | false groupMoney, string | nil error
mnr.rpc.handle('mnr_core:server:GroupFundView', function(source, groupName)
    local caller = playerCache.getPlayer(source)
    local group = groupsCache:getGroup(groupName)
    local callerGroup = caller:getGroup(groupName)

    local success, err = actionCheck(caller, group, callerGroup, 'fund', 'view')
    if not success then
        return false, err
    end

    return group.money, nil
end)

---@param source number
---@param groupName string
---@param action 'deposit' | 'withdraw'
---@return boolean success, string | nil error
mnr.rpc.handle('mnr_core:server:GroupFundAction', function(source, groupName, action, amount, account)
    local caller = playerCache.getPlayer(source)
    local group = groupsCache:getGroup(groupName)
    local callerGroup = caller:getGroup(groupName)

    local success, err = actionCheck(caller, group, callerGroup, 'fund', action)
    if not success then
        return false, err
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

exports('SetGroupMoney', function(name, moneyType, operator)
    local group = groupsCache.getGroup(name)

    return group and group:setMoney(moneyType, amount, operator) or false
end)