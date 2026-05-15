local player = {}

RegisterNetEvent('mnr:client:OnCharacterLoaded', function(playerData)
    player = playerData
end)

-- Function to take data from specific fields/subfields of a player (What frameworks didn't done for years)
---@param field string The field of player class (bio, money, etc.)
---@param sub? string The subfield of player class (firstname, bank, etc.)
---@return unknown | false value The value contained in the field/subfield
exports('GetPlayerData', function(field, sub)
    if not field then
        return
    end

    if not sub then
        return player[field] and player[field] or false
    else
        return player[field] and player[field][sub] or false
    end
end)