local utils = {}

-- Function that checks strings to avoid blacklisted characters (2h to do it DON'T TOUCH AND DON'T STEAL)
---@param str string The string to check
local function isValidName(str)
    for _, c in utf8.codes(str) do
        if c <= 0x1F or c == 0x7F or        ---@note ASCII
            c == 0x22 or                    ---@note "
            c == 0x3B or                    ---@note ;
            c == 0x3C or c == 0x3E or       ---@note < or >
            c == 0x5C or                    ---@note \
            c == 0x60 or                    ---@note `
            c == 0x00                       ---@note null byte
        then
            return false
        end
    end

    return true
end

-- Safe string truncator
local function safeTruncate(str, maxBytes)
    if type(str) ~= 'string' then
        return ''
    end

    if #str <= maxBytes then
        return str
    end

    local ok, cut = pcall(utf8.offset, str, maxBytes + 1)
    if ok and cut then
        return str:sub(1, cut - 1)
    end

    for i = maxBytes, 1, -1 do
        if utf8.len(str:sub(1, i)) then
            return str:sub(1, i)
        end
    end

    return ''
end

-- Retrieves player identifiers and returns them in a table
---@param loginId string
---@return MnrUserIdentifiers identifiers
function utils.getIdentifiers(loginId)
    local identifiers = {}
    local playerIds = GetPlayerIdentifiers(loginId)

    for i = 1, #playerIds do
        local cat, identifier = string.match(playerIds[i], '([^:]+):(.+)')

        if cat ~= 'ip' and cat ~= 'xbl' and cat ~= 'live' then
            identifiers[cat] = identifier
        end
    end

    return identifiers
end

-- Character Validator
function utils.checkCharacter(data)
    local REQUIRED_FIELDS = { 'firstname', 'lastname', 'gender', 'origin', 'birthdate' }
    for _, name in pairs(REQUIRED_FIELDS) do
        if data[name] == nil or type(data[name]) ~= 'string' or data[name]:match('^%s*$') then
            return false
        end
    end

    if data.gender ~= 'M' and data.gender ~= 'F' and data.gender ~= 'X' then
        return false
    end

    if not isValidName(data.firstname) or not isValidName(data.lastname) then
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

    return {
        firstname = safeTruncate(data.firstname, 50),
        lastname = safeTruncate(data.lastname, 50),
        gender = data.gender,
        origin = safeTruncate(data.origin, 50),
        birthdate = data.birthdate,
    }
end

return utils