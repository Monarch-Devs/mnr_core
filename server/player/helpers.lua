local helpers = {}

-- Identifiers retriever
function helpers.getIdentifiersBySource(source)
    local identifiers = {}

    identifiers.license = GetPlayerIdentifierByType(source, 'license')
    identifiers.license2 = GetPlayerIdentifierByType(source, 'license2')
    identifiers.fivem = GetPlayerIdentifierByType(source, 'fivem')
    identifiers.steam = GetPlayerIdentifierByType(source, 'steam')
    identifiers.discord = GetPlayerIdentifierByType(source, 'discord')

    return identifiers
end

-- Character Validator
function helpers.checkCharacter(data)
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

    if #data.firstname > 25 then
        data.firstname = data.firstname:sub(1, 25)
    end

    if #data.lastname > 25 then
        data.lastname = data.lastname:sub(1, 25)
    end

    if #data.origin > 25 then
        data.origin = data.origin:sub(1, 25)
    end

    return data
end

return helpers