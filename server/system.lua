AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then
        return
    end

    if GetResourceMetadata(name, 'name', 0) ~= name then
        error('[MONARCH] Wrong resource name detected, fix it', 0)
    end
end)