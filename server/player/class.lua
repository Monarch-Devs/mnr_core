---@class MnrPlayer
---@field userId number

local MnrPlayer = {}
MnrPlayer.__index = MnrPlayer

-- Constructor function
---@param userId number User ID retrieved from database
function MnrPlayer.new(userId)
    return setmetatable({ userId = userId }, MnrPlayer)
end

-- Class expansion function (Biography)
---@param data table Data of the character selected
function MnrPlayer:loadChar(data)
    self.charId = data.charId

    self.bio = {
        firstname = data.firstname,
        lastname = data.lastname,
        gender = data.gender,
        origin = data.origin,
        birthdate = data.birthdate,
    }
end

return MnrPlayer