local db = require 'server.player.db'

local MnrStatus = {}

function MnrStatus.load(charId)
    local data = db.getStatus(charId)

    return data or { health = 200, armor = 0, hunger = 100, thirst = 100, stress = 0 }
end

function MnrStatus.save(charId, data)
    if not data then
        return
    end

    db.saveStatus(charId, data)
end

return MnrStatus