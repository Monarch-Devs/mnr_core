local groups = require 'config.groups'

local db = require 'server.groups.db'

local function updateGroups()
    local result = { added = 0, deleted = 0 }

    local dbGroups = db.getGroupsNames()

    if not dbGroups then
        goto continue                       ---@note First server start (DB population not done)
    end

    for name in pairs(dbGroups) do
        local count = db.getGroupIsUsed(name)
        if not count or count == 0 then
            db.deleteGroup(name)
            result.deleted += 1
            print(('[mnr_core] Group "%s" removed from DB (no active assignments)'):format(name))
        elseif count > 0 then
            print(('[mnr_core] WARNING: group "%s" removed from config but %d characters still have it (keeping in DB)'):format(name, count))
        end
    end

    ::continue::

    for name, group in pairs(groups) do
        db.addGroup(name, group.label, group.cat)

        for level, grade in pairs(group.grades) do
            db.addGrade(name, level, grade.label)
        end

        result.added += 1
    end

    return result
end

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then return end

    CreateThread(function()
        local result = updateGroups()

        if result.added > 0 or result.deleted > 0 then
            print(('[MONARCH GROUPS]: updated DB with "config/groups.lua" groups (Added: %d, Deleted: %d)'):format(result.added, result.deleted))
        end

        ---@todo GROUP LOGIC
    end)
end)