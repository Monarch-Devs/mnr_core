local helper = {}

-- Identifiers retriever
function helper.getIdentifiersBySource(source)
    local identifiers = {}

    identifiers.license = GetPlayerIdentifierByType(source, 'license')
    identifiers.license2 = GetPlayerIdentifierByType(source, 'license2')
    identifiers.fivem = GetPlayerIdentifierByType(source, 'fivem')
    identifiers.steam = GetPlayerIdentifierByType(source, 'steam')
    identifiers.discord = GetPlayerIdentifierByType(source, 'discord')

    return identifiers
end

-- Safe string truncator
function helper.safeTruncate(str, maxBytes)
    if #str <= maxBytes then
        return str
    end

    local cut = utf8.offset(str, maxBytes + 1)
    if cut then
        return str:sub(1, cut - 1)
    end

    ---@todo Sanitize instead of returning empty string
    return ''
end

-- Character Validator
function helper.checkCharacter(data)
    local REQUIRED_FIELDS = { 'firstname', 'lastname', 'gender', 'origin', 'birthdate' }
    for _, name in pairs(REQUIRED_FIELDS) do
        if data[name] == nil or type(data[name]) ~= 'string' or data[name]:match('^%s*$') then
            return false
        end
    end

    if data.gender ~= 'M' and data.gender ~= 'F' and data.gender ~= 'X' then
        return false
    end

    local y, m, d
    if data.birthdate:match('^%d%d%d%d%-%d%d%-%d%d$') then
        y, m, d = data.birthdate:match('(%d%d%d%d)%-(%d%d)%-(%d%d)')
    elseif data.birthdate:match('^%d%d/%d%d/%d%d%d%d$') then
        d, m, y = data.birthdate:match('(%d%d)/(%d%d)/(%d%d%d%d)')
    else
        return false
    end

    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    if not y or not m or not d then
        return false
    end

    local timestamp = os.time({ year = y, month = m, day = d })
    if not timestamp then
        return false
    end

    local now = os.time()
    local age = (now - timestamp) / (365.25 * 24 * 3600)
    if age < 18 or age > 99 then
        return false
    end

    data.firstname = helper.safeTruncate(data.firstname, 50)
    data.lastname = helper.safeTruncate(data.lastname, 50)
    data.origin = helper.safeTruncate(data.origin, 50)

    return data
end

return helper