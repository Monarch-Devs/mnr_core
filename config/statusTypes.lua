---@description Status config: decrease can be false (not decreases) or a number that's the value decreased each interval (stress decreases for relief)
return {
    health = { degrade = false, default = 200, min = 0, max = 200 },
    armour = { degrade = false, default = 100, min = 0, max = 100 },
    hunger = { degrade = 10, default = 100, min = 0, max = 100 },
    thirst = { degrade = 5, default = 100, min = 0, max = 100 },
    stress = { degrade = 5, default = 0, min = 0, max = 100 },
}