SystemReady = false
local start = os.time()

local function checkSystemReady()
    if os.time() - start >= 60 and not SystemReady then
        SystemReady = true
        ---@todo [OPTIONAL] Event trigger to notify other scripts that the system is ready
        -- TriggerEvent('mnr:SystemReady')
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    start = os.time()
    SetTimeout(60000, checkSystemReady)
end)

SetTimeout(60000, checkSystemReady)