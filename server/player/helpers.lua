local helpers = {}

function helpers.getIdentifiersBySource(source)
    local identifiers = {}

    identifiers.license = GetPlayerIdentifierByType(source, 'license')
    identifiers.license2 = GetPlayerIdentifierByType(source, 'license2')
    identifiers.fivem = GetPlayerIdentifierByType(source, 'fivem')
    identifiers.steam = GetPlayerIdentifierByType(source, 'steam')
    identifiers.discord = GetPlayerIdentifierByType(source, 'discord')

    return identifiers
end

return helpers