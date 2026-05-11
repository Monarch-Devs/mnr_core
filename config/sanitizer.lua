---@description This is a table of blacklisted characters for a string sanitizer function (Don't edit unless you know what you are doing)
return {
    [0x00] = true,                  ---@note null byte
    [0x22] = true,                  ---@note "
    [0x3B] = true,                  ---@note ;
    [0x3C] = true,                  ---@note <
    [0x3E] = true,                  ---@note >
    [0x5C] = true,                  ---@note \
    [0x60] = true,                  ---@note `
    [0x7F] = true,                  ---@note ASCII
}