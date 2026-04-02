local db = require 'server.player.db'

local status = {}

function status.load(charId)
    local data = db.getStatus(charId)

    return data or { health = 200, armor = 0, hunger = 100.0, thirst = 100.0 }
end

function status.save(charId, data)
    if not data then
        return
    end

    db.saveStatus(charId, data)
end

return status