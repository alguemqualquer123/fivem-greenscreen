local resName = GetCurrentResourceName()

AddEventHandler('onResourceStart', function(resource)
    if resource ~= resName then return end
    print('[greenscreener] Resource started - API at ' .. Config.API_URL)
end)
