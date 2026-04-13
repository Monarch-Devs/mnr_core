local groups = require 'config.groups'

local groupsCache = require 'server.groups.cache'
local MnrGroup = require 'server.groups.class'
local db = require 'server.groups.db'

local function updateGroups()
    local dbGroups = db.getGroupsNames()

    if not dbGroups then
        goto sync_groups                       ---@note First server start (DB population not done)
    end

    for name in pairs(dbGroups) do
        local count = db.getGroupIsUsed(name)
        if not count or count == 0 then
            db.deleteGroup(name)
            print(('[mnr_core] Group "%s" removed from DB (no active assignments)'):format(name))
        elseif count > 0 then
            print(('[mnr_core] WARNING: group "%s" removed from config but %d characters still have it (keeping in DB)'):format(name, count))
        end
    end

    ::sync_groups::

    for name, group in pairs(groups) do
        db.addGroup(name, group.label, group.cat)

        for level, grade in pairs(group.grades) do
            db.addGrade(name, level, grade.label)
        end

        groupsCache.addGroup(name, MnrGroup.new(name, group.cat))
    end
end

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then return end

    CreateThread(function()
        updateGroups()
        ---@todo GROUP LOGIC
    end)
end)