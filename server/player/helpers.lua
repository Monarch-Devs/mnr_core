local ErrorFlags = require 'data.errors'

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

-- Normalizator
function helpers.capitalize(str)
    if type(str) ~= 'string' then
        return str
    end

    str = str:lower()

    return (str:gsub('^%l', string.upper))
end

function helpers.isNameValid(str)
    return type(str) == 'string' and str:match('^[A-Za-zÀ-ÖØ-öø-ÿ\'%-]+$') ~= nil
end

-- Birthdate Validator
function helpers.isValidBirthdate(dateString)
    if type(dateString) ~= 'string' then
        return false
    end

    local y, m, d

    if dateString:match('^%d%d%d%d%-%d%d%-%d%d$') then
        y, m, d = dateString:match('(%d%d%d%d)%-(%d%d)%-(%d%d)')
    elseif dateString:match('^%d%d/%d%d/%d%d%d%d$') then
        d, m, y = dateString:match('(%d%d)/(%d%d)/(%d%d%d%d)')
    else
        return false
    end

    y = tonumber(y)
    m = tonumber(m)
    d = tonumber(d)

    if not y or not m or not d then return false end

    local timestamp = os.time({ year = y, month = m, day = d })
    if not timestamp then return false end

    local now = os.time()
    local age = (now - timestamp) / (365.25 * 24 * 3600)

    return age >= 18 and age <= 99
end

-- [EXPERIMENTAL] Biography Validator (Flag system)
function helpers.checkBio(data)
    local error_flag = 0

    data.firstname = helpers.capitalize(data.firstname)
    data.lastname = helpers.capitalize(data.lastname)
    data.origin = helpers.capitalize(data.origin)

    if type(data.firstname) ~= 'string' or #data.firstname < 2 or #data.firstname > 20 or not helpers.isNameValid(data.firstname) then
        error_flag = error_flag | ErrorFlags.INVALID_FIRSTNAME
    end

    if type(data.lastname) ~= 'string' or #data.lastname < 2 or #data.lastname > 24 or not helpers.isNameValid(data.lastname) then
        error_flag = error_flag | ErrorFlags.INVALID_LASTNAME
    end

    if data.gender ~= 'M' and data.gender ~= 'F' and data.gender ~= 'X' then
        error_flag = error_flag | ErrorFlags.INVALID_GENDER
    end

    if type(data.origin) ~= 'string' or #data.origin < 2 or #data.origin > 30 or not helpers.isNameValid(data.origin) then
        error_flag = error_flag | ErrorFlags.INVALID_ORIGIN
    end

    if not helpers.isValidBirthdate(data.birthdate) then
        error_flag = error_flag | ErrorFlags.INVALID_BIRTHDATE
    end

    return error_flag
end

return helpers