---@class MnrPlayer
---@field userId number

local status = require 'server.player.status'
local groups = require 'server.player.groups'

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

    self.status = {
        health = data.health  or 200,
        armor = data.armor   or 0,
        hunger = data.hunger  or 100.0,
        thirst = data.thirst  or 100.0,
    }

    self.groups = data.groups or {}
end

function MnrPlayer:save()
    if not self.charId then return end

    status.save(self.charId, self.status)
    groups.save(self.charId, self.groups)
end

return MnrPlayer