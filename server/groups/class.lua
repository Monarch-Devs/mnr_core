local MnrGroup = {}
MnrGroup.__index = MnrGroup

function MnrGroup.new(name, cat)
    return setmetatable({
        name = name,
        cat = cat,
        duty = {},
        online = {},
        offline = {},
    }, MnrPlayer)
end

return MnrGroup