local groups = require 'config.groups'
local groupsCache = require 'server.groups.cache'
local MnrGroup = require 'server.groups.class'
local db = require 'server.groups.db'

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

        groupsCache.addGroup(name, MnrGroup.new(name, group.cat, { bossPerms = group.bossPerms, fundPerms = group.fundPerms }))
    end

    print('[mnr_core] Groups cleanup completed')
end

CreateThread(dbGroupsCleanup)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then return end

    for _, group in pairs(groupsCache.getAllGroups()) do
        group:saveMoney()
    end
end)

exports('GetGroupMoney', function(name, moneyType)
    local group = groupsCache.getGroup(name)

    return group and group:getMoney(moneyType) or 0
end)

exports('SetGroupMoney', function(name, moneyType, operator)
    local group = groupsCache.getGroup(name)

    return group and group:setMoney(moneyType, amount, operator) or false
end)