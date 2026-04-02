local db = require 'server.player.db'

local groups = {}

function groups.load(charId)
    local data = db.getGroups(charId)

    return data or {}
end

function groups.save(charId, data)
    if not data then
        return
    end

    for _, group in ipairs(data) do
        db.saveGroup(charId, group)
    end
end

function groups.set(charId, groupList, type, name, grade)
    db.saveGroup(charId, { type = type, name = name, grade = grade })

    for _, group in ipairs(groupList) do
        if group.type == type then
            group.name  = name
            group.grade = grade
            return groupList
        end
    end

    groupList[#groupList + 1] = { type = type, name = name, grade = grade }

    return groupList
end

function groups.remove(charId, groupList, type)
    db.deleteGroup(charId, type)

    for i, group in ipairs(groupList) do
        if group.type == type then
            groupList[i] = nil

            return groupList
        end
    end

    return groupList
end

return groups