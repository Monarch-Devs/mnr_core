local player = {}

RegisterNetEvent('mnr_core:client:CharacterLoaded', function(data)
    player.bio = {
        charId = data.charId,
        firstname = data.firstname,
        lastname = data.lastname,
        gender = data.gender,
        origin = data.origin,
        birthdate = data.birthdate,
    }
end)

local function getPlayerData(field, sub)
    if not player[field] then
        return false
    end

    if not sub then
        return player[field]
    else
        return player[field][sub]
    end
end

exports('GetPlayerData', getPlayerData)