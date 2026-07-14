local resName = GetCurrentResourceName()

AddEventHandler('onResourceStart', function(resource)
    if resource ~= resName then return end
    print('[greenscreener] Resource started - API at http://127.0.0.1:3210')
end)
