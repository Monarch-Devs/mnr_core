local groupsCache = {}

local _groups = {}
local _categories = {}

function groupsCache.addGroup(name, group)
    _groups[name] = group

    if not _categories[group.cat] then
        _categories[group.cat] = {}
    end

    local categoryCache = _categories[group.cat]
    categoryCache[#categoryCache + 1] = name
end

function groupsCache.getGroup(name)
    return _groups[name] or false
end

function groupsCache.getCatGroups(cat)
    local category = _categories[cat]
    if not category then
        return false
    end

    local result = {}
    for i = 1, #category do
        result[i] = _groups[category[i]]
    end

    return result
end

function groupsCache.getAllGroups()
    return _groups
end

return groupsCache