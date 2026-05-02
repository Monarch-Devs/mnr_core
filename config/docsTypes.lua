local function duration(t)
    return (t.days or 0) * 86400 + (t.hours or 0) * 3600 + (t.minutes or 0) * 60 + (t.seconds or 0)
end

return {
    id_card = { starter = true, duration = false --[[No expiration]]},
    driver_license = { starter = false, duration = duration({ days = 30 }) --[[30 days in simple way]]},
    weapon_license = { starter = false, duration = 2592000 --[[30 days if you are masochist]]},
}