local cam = nil
local camInfo = nil
local ped = nil
local playerId = PlayerId()
local QBCore = nil

local API_URL = Config.API_URL or 'http://127.0.0.1:3210'

if Config.useQBVehicles then
    QBCore = exports[Config.coreResourceName]:GetCoreObject()
end

-- ============================================
-- Utility
-- ============================================

local function setWeatherTime()
    if Config.debug then print('[greenscreener] Setting Weather & Time') end
    SetRainLevel(0.0)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(18, 0, 0)
    NetworkOverrideClockMillisecondsPerGameMinute(1000000)
end

local function stopWeatherResource()
    if Config.debug then print('[greenscreener] Stopping Weather Resource') end
    if GetResourceState('qb-weathersync') == 'started' or GetResourceState('qbx_weathersync') == 'started' then
        TriggerEvent('qb-weathersync:client:DisableSync')
        return true
    elseif GetResourceState('weathersync') == 'started' then
        TriggerEvent('weathersync:toggleSync')
        return true
    elseif GetResourceState('esx_wsync') == 'started' then
        SendNUIMessage({ error = 'weathersync' })
        return false
    elseif GetResourceState('cd_easytime') == 'started' then
        TriggerEvent('cd_easytime:PauseSync', false)
        return true
    elseif GetResourceState('vSync') == 'started' or GetResourceState('Renewed-Weathersync') == 'started' then
        TriggerEvent('vSync:toggle', false)
        return true
    end
    return true
end

local function startWeatherResource()
    if Config.debug then print('[greenscreener] Starting Weather Resource again') end
    if GetResourceState('qb-weathersync') == 'started' or GetResourceState('qbx_weathersync') == 'started' then
        TriggerEvent('qb-weathersync:client:EnableSync')
    elseif GetResourceState('weathersync') == 'started' then
        TriggerEvent('weathersync:toggleSync')
    elseif GetResourceState('cd_easytime') == 'started' then
        TriggerEvent('cd_easytime:PauseSync', true)
    elseif GetResourceState('vSync') == 'started' or GetResourceState('Renewed-Weathersync') == 'started' then
        TriggerEvent('vSync:toggle', true)
    end
end

local function destroyCam()
    if cam then
        DestroyAllCams(true)
        DestroyCam(cam, true)
        cam = nil
    end
end

local function clearAllPedProps()
    for prop, _ in pairs(Config.cameraSettings.PROPS) do
        ClearPedProp(ped, tonumber(prop))
    end
end

local function resetPedComponents()
    if Config.debug then print('[greenscreener] Resetting Ped Components') end
    SetPedDefaultComponentVariation(ped)
    Wait(150)
    SetPedComponentVariation(ped, 0, 0, 1, 0)
    SetPedComponentVariation(ped, 1, 0, 0, 0)
    SetPedComponentVariation(ped, 2, -1, 0, 0)
    SetPedComponentVariation(ped, 7, 0, 0, 0)
    SetPedComponentVariation(ped, 5, 0, 0, 0)
    SetPedComponentVariation(ped, 6, -1, 0, 0)
    SetPedComponentVariation(ped, 9, 0, 0, 0)
    SetPedComponentVariation(ped, 3, -1, 0, 0)
    SetPedComponentVariation(ped, 8, -1, 0, 0)
    SetPedComponentVariation(ped, 4, -1, 0, 0)
    SetPedComponentVariation(ped, 11, -1, 0, 0)
    SetPedHairColor(ped, 45, 15)
    clearAllPedProps()
end

local function setPedOnGround()
    local coords = GetEntityCoords(ped, false)
    local retval, ground = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    SetEntityCoords(ped, coords.x, coords.y, ground, false, false, false, false)
end

local function loadComponentVariation(component, drawable, texture)
    texture = texture or 0
    if Config.debug then print('[greenscreener] Loading Component: ' .. component .. ' ' .. drawable .. ' ' .. texture) end
    SetPedPreloadVariationData(ped, component, drawable, texture)
    while not HasPedPreloadVariationDataFinished(ped) do
        Wait(50)
    end
    SetPedComponentVariation(ped, component, drawable, texture, 0)
end

local function loadPropVariation(component, prop, texture)
    texture = texture or 0
    if Config.debug then print('[greenscreener] Loading Prop: ' .. component .. ' ' .. prop .. ' ' .. texture) end
    SetPedPreloadPropData(ped, component, prop, texture)
    while not HasPedPreloadPropDataFinished(ped) do
        Wait(50)
    end
    ClearPedProp(ped, component)
    SetPedPropIndex(ped, component, prop, texture, 0)
end

-- ============================================
-- Screenshot helper
-- ============================================

local function doScreenshot(filename, type)
    if API_URL and API_URL ~= '' then
        exports['screenshot-basic']:requestScreenshot({
            encoding = 'png',
            quality = 1.0,
        }, function(data)
            SendNUIMessage({
                action = 'saveLocal',
                apiUrl = API_URL,
                dataUrl = data,
                filename = type .. '/' .. filename,
                debug = Config.debug,
            })
        end)
    elseif Config.webhook and Config.webhook ~= '' then
        exports['screenshot-basic']:requestScreenshotUpload(Config.webhook, 'file', {
            encoding = 'png',
            quality = 1.0,
        }, function(data)
            if Config.debug then
                print('[greenscreener] Uploaded: ' .. type .. '/' .. filename)
            end
        end)
    else
        exports['screenshot-basic']:requestScreenshot({
            encoding = 'png',
            quality = 1.0,
            fileName = 'images/' .. type .. '/' .. filename .. '.png',
        })
    end
end

-- ============================================
-- Screenshot functions
-- ============================================

local function takeScreenshotForComponent(pedType, type, component, drawable, texture, cameraSettings)
    local cameraInfo = cameraSettings or Config.cameraSettings[type][tostring(component)]

    setWeatherTime()
    Wait(100)

    if not camInfo or camInfo.zPos ~= cameraInfo.zPos or camInfo.fov ~= cameraInfo.fov then
        camInfo = cameraInfo
        destroyCam()

        SetEntityRotation(ped, Config.greenScreenRotation.x, Config.greenScreenRotation.y, Config.greenScreenRotation.z, 0, false)
        SetEntityCoordsNoOffset(ped, Config.greenScreenPosition.x, Config.greenScreenPosition.y, Config.greenScreenPosition.z, false, false, false)
        Wait(50)

        local coords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)

        local fwdX, fwdY, fwdZ
        if fwd then
            fwdX = fwd.x
            fwdY = fwd.y
            fwdZ = fwd.z
        else
            local rad = math.rad(Config.greenScreenRotation.z)
            fwdX = -math.sin(rad)
            fwdY = math.cos(rad)
            fwdZ = 0.0
        end

        local fwdPos = {
            x = coords.x + fwdX * 1.2,
            y = coords.y + fwdY * 1.2,
            z = coords.z + fwdZ + cameraInfo.zPos,
        }

        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', fwdPos.x, fwdPos.y, fwdPos.z, 0, 0, 0, cameraInfo.fov, true, 0)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + cameraInfo.zPos)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false, 0)
    end

    Wait(50)
    SetEntityRotation(ped, camInfo.rotation.x, camInfo.rotation.y, camInfo.rotation.z, 2, false)

    local propName = type == 'PROPS' and 'prop_' or ''
    local texStr = texture and ('_' .. texture) or ''
    local filename = pedType .. '_' .. propName .. component .. '_' .. drawable .. texStr
    doScreenshot(filename, 'clothing')
    Wait(1500)
end

local function takeScreenshotForObject(object, modelHash, angle)
    setWeatherTime()
    Wait(100)
    destroyCam()

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(100)
        end
    end

    local minVec, maxVec = GetModelDimensions(modelHash)
    local minDimX = minVec and minVec.x or -0.5
    local minDimY = minVec and minVec.y or -0.5
    local minDimZ = minVec and minVec.z or -0.5
    local maxDimX = maxVec and maxVec.x or 0.5
    local maxDimY = maxVec and maxVec.y or 0.5
    local maxDimZ = maxVec and maxVec.z or 0.5

    local modelSize = {
        x = maxDimX - minDimX,
        y = maxDimY - minDimY,
        z = maxDimZ - minDimZ,
    }

    local coords = GetEntityCoords(object, false)

    local center = {
        x = coords.x + (minDimX + maxDimX) / 2,
        y = coords.y + (minDimY + maxDimY) / 2,
        z = coords.z + (minDimZ + maxDimZ) / 2,
    }

    -- Calculate the maximum dimension across all axes
    local maxAll = math.max(modelSize.x, modelSize.y, modelSize.z)

    -- Adaptive camera distance based on object size
    -- Increased distances to avoid cutting off objects
    local camDist
    if maxAll < 0.5 then
        -- Tiny objects (small props, food items)
        camDist = maxAll + 1.5
    elseif maxAll < 1.5 then
        -- Medium objects (bags, hats, small wings)
        camDist = maxAll + 2.5
    elseif maxAll < 3.0 then
        -- Large objects (big wings, large props)
        camDist = maxAll + 3.5
    else
        -- Extra large objects (huge wings, massive props)
        camDist = maxAll + 5.0
    end

    -- Adaptive FOV based on object size
    local fov
    if maxAll < 0.5 then
        fov = 25
    elseif maxAll < 1.0 then
        fov = 30
    elseif maxAll < 2.0 then
        fov = 35
    elseif maxAll < 4.0 then
        fov = 45
    else
        fov = 55
    end

    -- Adjust camera height based on object height
    local camHeight = modelSize.z / 4
    if modelSize.z > 2.0 then
        camHeight = modelSize.z / 5
    end

    -- Use object heading to position camera in FRONT
    local heading = GetEntityHeading(object)
    local rad = math.rad(heading)

    local camPos = {
        x = center.x + camDist * math.sin(rad),
        y = center.y - camDist * math.cos(rad),
        z = center.z + camHeight,
    }

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0, 0, 0, fov, true, 0)
    PointCamAtCoord(cam, center.x, center.y, center.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)

    Wait(50)
    doScreenshot(tostring(modelHash), 'objects')
    Wait(1500)
end

local function takeScreenshotForVehicle(vehicle, modelHash, modelName)
    setWeatherTime()
    Wait(100)
    destroyCam()

    local minVec, maxVec = GetModelDimensions(modelHash)
    local minDimX = minVec and minVec.x or -2.0
    local minDimY = minVec and minVec.y or -2.0
    local minDimZ = minVec and minVec.z or -0.5
    local maxDimX = maxVec and maxVec.x or 2.0
    local maxDimY = maxVec and maxVec.y or 2.0
    local maxDimZ = maxVec and maxVec.z or 1.5

    local modelSize = {
        x = maxDimX - minDimX,
        y = maxDimY - minDimY,
        z = maxDimZ - minDimZ,
    }
    local fov = math.min(math.max(modelSize.x, modelSize.y, modelSize.z) / 0.15 * 10, 60)

    local coords = GetEntityCoords(vehicle, false)

    local center = {
        x = coords.x + (minDimX + maxDimX) / 2,
        y = coords.y + (minDimY + maxDimY) / 2,
        z = coords.z + (minDimZ + maxDimZ) / 2,
    }

    local maxAll = math.max(modelSize.x, modelSize.y, modelSize.z)
    local camPos = {
        x = center.x + (maxAll + 2) * math.cos(math.rad(340)),
        y = center.y + (maxAll + 2) * math.sin(math.rad(340)),
        z = center.z + modelSize.z / 2,
    }

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0, 0, 0, fov, true, 0)
    PointCamAtCoord(cam, center.x, center.y, center.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)

    Wait(50)
    doScreenshot(modelName, 'vehicles')
    Wait(1500)
end

-- ============================================
-- Commands
-- ============================================

RegisterCommand('screenshot', function(source, args)
    Citizen.CreateThread(function()
        local modelHashes = { GetHashKey('mp_m_freemode_01'), GetHashKey('mp_f_freemode_01') }

        SendNUIMessage({ start = true })
        if not stopWeatherResource() then return end
        DisableIdleCamera(true)
        Wait(100)

        for _, modelHash in ipairs(modelHashes) do
            if IsModelValid(modelHash) then
                if not HasModelLoaded(modelHash) then
                    RequestModel(modelHash)
                    while not HasModelLoaded(modelHash) do
                        Wait(100)
                    end
                end

                SetPlayerModel(playerId, modelHash)
                Wait(150)
                SetModelAsNoLongerNeeded(modelHash)
                Wait(150)

                ped = PlayerPedId()
                local pedType = modelHash == GetHashKey('mp_m_freemode_01') and 'male' or 'female'

                SetEntityRotation(ped, Config.greenScreenRotation.x, Config.greenScreenRotation.y, Config.greenScreenRotation.z, 0, false)
                SetEntityCoordsNoOffset(ped, Config.greenScreenPosition.x, Config.greenScreenPosition.y, Config.greenScreenPosition.z, false, false, false)
                FreezeEntityPosition(ped, true)
                Wait(50)
                SetPlayerControl(playerId, false)

                local shouldClear = true
                Citizen.CreateThread(function()
                    while shouldClear do
                        ClearPedTasksImmediately(ped)
                        Wait(0)
                    end
                end)

                for typeName, components in pairs(Config.cameraSettings) do
                    for compStr, compData in pairs(components) do
                        resetPedComponents()
                        Wait(150)
                        local component = tonumber(compStr)

                        if typeName == 'CLOTHING' then
                            local drawableCount = GetNumberOfPedDrawableVariations(ped, component)
                            for drawable = 0, drawableCount - 1 do
                                local texCount = GetNumberOfPedTextureVariations(ped, component, drawable)
                                SendNUIMessage({ type = compData.name, value = drawable, max = drawableCount })
                                if Config.includeTextures then
                                    for texture = 0, texCount - 1 do
                                        loadComponentVariation(component, drawable, texture)
                                        takeScreenshotForComponent(pedType, typeName, component, drawable, texture)
                                    end
                                else
                                    loadComponentVariation(component, drawable)
                                    takeScreenshotForComponent(pedType, typeName, component, drawable)
                                end
                            end
                        elseif typeName == 'PROPS' then
                            local propCount = GetNumberOfPedPropDrawableVariations(ped, component)
                            for prop = 0, propCount - 1 do
                                local texCount = GetNumberOfPedPropTextureVariations(ped, component, prop)
                                SendNUIMessage({ type = compData.name, value = prop, max = propCount })
                                if Config.includeTextures then
                                    for texture = 0, texCount - 1 do
                                        loadPropVariation(component, prop, texture)
                                        takeScreenshotForComponent(pedType, typeName, component, prop, texture)
                                    end
                                else
                                    loadPropVariation(component, prop)
                                    takeScreenshotForComponent(pedType, typeName, component, prop)
                                end
                            end
                        end
                    end
                end

                shouldClear = false
                SetModelAsNoLongerNeeded(modelHash)
                SetPlayerControl(playerId, true)
                FreezeEntityPosition(ped, false)
            end
        end

        setPedOnGround()
        startWeatherResource()
        SendNUIMessage({ ["end"] = true })
        destroyCam()
        RenderScriptCams(false, false, 0, true, false, 0)
        camInfo = nil
    end)
end, false)

-- ============================================
-- Screenshotprops with Placement
-- ============================================

local placeMode = {
    active = false,
    object = nil,
    modelHash = nil,
    modelName = '',
    pos = nil,
    rot = nil,
    confirmed = false,
    fov = 40.0,
}

local function startPlacementMode(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelValid(hash) then
        print('[greenscreener] Invalid model: ' .. modelName)
        return false
    end

    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(100)
        end
    end

    local gPos = Config.greenScreenPosition
    local gRot = Config.greenScreenRotation

    placeMode.active = true
    placeMode.modelHash = hash
    placeMode.modelName = modelName
    placeMode.pos = vector3(gPos.x, gPos.y, gPos.z)
    placeMode.rot = vector3(gRot.x, gRot.y, gRot.z + 180)
    placeMode.confirmed = false

    placeMode.object = CreateObjectNoOffset(hash, gPos.x, gPos.y, gPos.z, false, true, true)
    if not placeMode.object or placeMode.object == 0 then
        print('[greenscreener] Failed to spawn: ' .. modelName)
        placeMode.active = false
        return false
    end

    FreezeEntityPosition(placeMode.object, true)
    SetEntityRotation(placeMode.object, placeMode.rot.x, placeMode.rot.y, placeMode.rot.z, 0, false)
    PlaceObjectOnGroundProperly(placeMode.object)

    return true
end

local function stopPlacementMode()
    if placeMode.object then
        DeleteEntity(placeMode.object)
        placeMode.object = nil
    end
    placeMode.active = false
    placeMode.confirmed = false
end

RegisterCommand('screenshotprops', function(source, args)
    Citizen.CreateThread(function()
        local propsList = Config.propsList

        if not propsList or #propsList == 0 then
            print('[greenscreener] ERROR: No props in propsList config')
            return
        end

        if not stopWeatherResource() then return end
        DisableIdleCamera(true)
        ped = PlayerPedId()
        SetEntityCoords(ped, Config.greenScreenHiddenSpot.x, Config.greenScreenHiddenSpot.y, Config.greenScreenHiddenSpot.z, false, false, false)
        setWeatherTime()
        Wait(100)

        -- Spawn first prop for placement
        local firstModel = propsList[1]
        if not startPlacementMode(firstModel) then
            startWeatherResource()
            return
        end

        -- Freeze player so they don't walk around
        FreezeEntityPosition(ped, true)

        -- Show NUI placement mode
        SendNUIMessage({
            action = 'placement',
            show = true,
            modelName = firstModel,
            index = 1,
            total = #propsList,
        })

        -- Camera setup
        local minVec, maxVec = GetModelDimensions(placeMode.modelHash)
        local minDimX = minVec and minVec.x or -0.5
        local minDimZ = minVec and minVec.z or -0.5
        local maxDimX = maxVec and maxVec.x or 0.5
        local maxDimZ = maxVec and maxVec.z or 0.5
        local modelHeight = maxDimZ - minDimZ
        local modelWidth = maxDimX - minDimX
        local camDist = math.max(modelWidth, modelHeight) + 2.0
        placeMode.fov = math.min(math.max(modelWidth, modelHeight) / 0.15 * 10, 60)

        local gPos = Config.greenScreenPosition
        destroyCam()
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', gPos.x, gPos.y - camDist, gPos.z + modelHeight / 2, 0, 0, 0, placeMode.fov, true, 0)
        PointCamAtCoord(cam, gPos.x, gPos.y, gPos.z + modelHeight / 2)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false, 0)
    

        -- Placement loop
        local camCoords = { x = gPos.x, y = gPos.y - camDist, z = gPos.z + modelHeight / 2 }
        local camRotX = 0.0
        local camRotZ = 0.0

        while placeMode.active and not placeMode.confirmed do
            Wait(0)

            -- Disable ALL controls
            for i = 0, 357 do
                DisableControlAction(0, i, true)
            end

            local pos = placeMode.pos
            local rot = placeMode.rot
            local moveSpeed = 0.05
            local camSpeed = 0.1
            local rotSpeed = 1.0
            local shift = IsDisabledControlPressed(0, 21)
            local ctrl = IsDisabledControlPressed(0, 36) -- Left Ctrl

            -- === OBJECT CONTROLS (arrows) ===
            if shift then
                -- Shift + Left/Right = rotate object
                if IsDisabledControlPressed(0, 174) then
                    rot = vector3(rot.x, rot.y, rot.z - rotSpeed)
                end
                if IsDisabledControlPressed(0, 175) then
                    rot = vector3(rot.x, rot.y, rot.z + rotSpeed)
                end
            elseif ctrl then
                -- Ctrl + Up/Down = move object up/down
                if IsDisabledControlPressed(0, 172) then
                    pos = vector3(pos.x, pos.y, pos.z + moveSpeed)
                end
                if IsDisabledControlPressed(0, 173) then
                    pos = vector3(pos.x, pos.y, pos.z - moveSpeed)
                end
            else
                -- Arrow keys = move object X/Y
                if IsDisabledControlPressed(0, 172) then
                    pos = vector3(pos.x, pos.y + moveSpeed, pos.z)
                end
                if IsDisabledControlPressed(0, 173) then
                    pos = vector3(pos.x, pos.y - moveSpeed, pos.z)
                end
                if IsDisabledControlPressed(0, 174) then
                    pos = vector3(pos.x - moveSpeed, pos.y, pos.z)
                end
                if IsDisabledControlPressed(0, 175) then
                    pos = vector3(pos.x + moveSpeed, pos.y, pos.z)
                end
            end

            placeMode.pos = pos
            placeMode.rot = rot
            SetEntityCoordsNoOffset(placeMode.object, pos.x, pos.y, pos.z, false, false, false)
            SetEntityRotation(placeMode.object, rot.x, rot.y, rot.z, 0, false)

            -- === CAMERA CONTROLS (freecam) ===
            local camFwd = GetCamRot(cam, 2)
            local camHeading = math.rad(camRotZ)

            -- W/S = camera forward/backward
            if IsDisabledControlPressed(0, 32) then
                camCoords.x = camCoords.x + camSpeed * math.sin(-camHeading)
                camCoords.y = camCoords.y + camSpeed * math.cos(-camHeading)
            end
            if IsDisabledControlPressed(0, 33) then
                camCoords.x = camCoords.x - camSpeed * math.sin(-camHeading)
                camCoords.y = camCoords.y - camSpeed * math.cos(-camHeading)
            end

            -- A/D = camera strafe left/right
            if IsDisabledControlPressed(0, 34) then
                camCoords.x = camCoords.x - camSpeed * math.cos(-camHeading)
                camCoords.y = camCoords.y + camSpeed * math.sin(-camHeading)
            end
            if IsDisabledControlPressed(0, 35) then
                camCoords.x = camCoords.x + camSpeed * math.cos(-camHeading)
                camCoords.y = camCoords.y - camSpeed * math.sin(-camHeading)
            end

            -- Q/E = camera up/down
            if IsDisabledControlPressed(0, 44) then
                camCoords.z = camCoords.z + camSpeed
            end
            if IsDisabledControlPressed(0, 20) then
                camCoords.z = camCoords.z - camSpeed
            end

            -- Mouse = camera look (using mouse delta)
            local mouseX = GetDisabledControlNormal(0, 1)  -- Mouse X
            local mouseY = GetDisabledControlNormal(0, 2)  -- Mouse Y
            camRotZ = camRotZ + mouseX * 3.0
            camRotX = camRotX - mouseY * 3.0
            camRotX = math.max(-89.0, math.min(89.0, camRotX))

            -- FOV = scroll
            if IsDisabledControlPressed(0, 14) then
                placeMode.fov = math.max(5.0, placeMode.fov - 1.0)
            end
            if IsDisabledControlPressed(0, 15) then
                placeMode.fov = math.min(120.0, placeMode.fov + 1.0)
            end

            SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
            SetCamRot(cam, camRotX, 0.0, camRotZ, 2)
            SetCamFov(cam, placeMode.fov)

            -- Confirm with Enter
            if IsDisabledControlJustPressed(0, 176) or IsDisabledControlJustPressed(0, 191) then
                FreezeEntityPosition(ped, false)
                placeMode.confirmed = true
                SendNUIMessage({ action = 'placement', show = false })
                print('[greenscreener] Confirmed! Starting batch...')
            end

            -- Exit with Backspace
            if IsDisabledControlJustPressed(0, 194) then
                FreezeEntityPosition(ped, false)
                stopPlacementMode()
                startWeatherResource()
                destroyCam()
                RenderScriptCams(false, false, 0, true, false, 0)
                SendNUIMessage({ action = 'placement', show = false })
                print('[greenscreener] Cancelled')
                return
            end
        end

        -- Save confirmed position/rotation
        local finalPos = placeMode.pos
        local finalRot = placeMode.rot
        stopPlacementMode()

        -- Batch screenshot with confirmed position
        SendNUIMessage({ start = true })

        local successCount = 0
        local failCount = 0

        for i = 1, #propsList do
            local modelName = propsList[i]
            local modelHash = GetHashKey(modelName)

            SendNUIMessage({ type = modelName, value = i, max = #propsList })

            local skip = false

            if not IsModelValid(modelHash) then
                if Config.debug then print('[greenscreener] Invalid model ' .. modelName) end
                failCount = failCount + 1
                skip = true
            end

            if not skip then
                if not HasModelLoaded(modelHash) then
                    RequestModel(modelHash)
                    local timeout = GetGameTimer() + Config.vehicleSpawnTimeout
                    local loaded = false
                    while not HasModelLoaded(modelHash) do
                        Wait(100)
                        if GetGameTimer() > timeout then
                            if Config.debug then print('[greenscreener] Timeout loading ' .. modelName) end
                            failCount = failCount + 1
                            loaded = false
                            break
                        end
                        loaded = true
                    end
                    if not loaded then skip = true end
                end
            end

            if not skip then
                local object = CreateObjectNoOffset(modelHash, finalPos.x, finalPos.y, finalPos.z, false, true, true)

                if not object or object == 0 then
                    if Config.debug then print('[greenscreener] Failed to spawn ' .. modelName) end
                    SetModelAsNoLongerNeeded(modelHash)
                    failCount = failCount + 1
                    skip = true
                end

                if not skip then
                    SetEntityRotation(object, finalRot.x, finalRot.y, finalRot.z, 0, false)
                    FreezeEntityPosition(object, true)
                    Wait(50)

                    takeScreenshotForObject(object, modelHash, 180)

                    DeleteEntity(object)
                    SetModelAsNoLongerNeeded(modelHash)
                    successCount = successCount + 1
                end
            end
        end

        FreezeEntityPosition(ped, false)
        startWeatherResource()
        SendNUIMessage({ ["end"] = true })
        destroyCam()
        RenderScriptCams(false, false, 0, true, false, 0)

        print('[greenscreener] Props done: ' .. successCount .. ' success, ' .. failCount .. ' failed, ' .. #propsList .. ' total')
    end)
end, false)

RegisterCommand('screenshotobject', function(source, args)
    Citizen.CreateThread(function()
        local modelName = args[1]
        local modelHash = tonumber(modelName) and tonumber(modelName) or GetHashKey(modelName)

        if IsWeaponValid(modelHash) then
            modelHash = GetWeapontypeModel(modelHash)
        end

        if not stopWeatherResource() then return end
        DisableIdleCamera(true)
        Wait(100)

        if not IsModelValid(modelHash) then
            print('[greenscreener] ERROR: Invalid object model')
            return
        end

        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do
                Wait(100)
            end
        end

        local playerPed = PlayerPedId()
        SetEntityCoords(playerPed, Config.greenScreenHiddenSpot.x, Config.greenScreenHiddenSpot.y, Config.greenScreenHiddenSpot.z, false, false, false)
        SetPlayerControl(playerId, false)

        if Config.debug then print('[greenscreener] Spawning Object ' .. modelHash) end

        local object = CreateObjectNoOffset(modelHash, Config.greenScreenPosition.x, Config.greenScreenPosition.y, Config.greenScreenPosition.z, false, true, true)
        SetEntityRotation(object, Config.greenScreenRotation.x, Config.greenScreenRotation.y, Config.greenScreenRotation.z, 0, false)
        FreezeEntityPosition(object, true)
        Wait(50)

        takeScreenshotForObject(object, modelHash)

        DeleteEntity(object)
        SetPlayerControl(playerId, true)
        SetModelAsNoLongerNeeded(modelHash)
        startWeatherResource()
        destroyCam()
        RenderScriptCams(false, false, 0, true, false, 0)
    end)
end, false)

RegisterCommand('screenshotvehicle', function(source, args)
    Citizen.CreateThread(function()
        local vehicles = nil
        if Config.useQBVehicles and QBCore ~= nil then
            vehicles = {}
            for k, _ in pairs(QBCore.Shared.Vehicles) do
                vehicles[#vehicles + 1] = k
            end
        else
            vehicles = GetAllVehicleModels()
        end

        local playerPed = PlayerPedId()
        local vehicleType = args[1] and string.lower(args[1]) or nil
        local primarycolor = args[2] and tonumber(args[2]) or nil
        local secondarycolor = args[3] and tonumber(args[3]) or nil

        if not vehicleType then
            SendNUIMessage({ error = 'noargs' })
            print('[greenscreener] Usage: /screenshotvehicle <model|all> [primarycolor] [secondarycolor]')
            return
        end

        if not stopWeatherResource() then return end
        DisableIdleCamera(true)
        SetEntityCoords(playerPed, Config.greenScreenHiddenSpot.x, Config.greenScreenHiddenSpot.y, Config.greenScreenHiddenSpot.z, false, false, false)
        SetPlayerControl(playerId, false)
        ClearAreaOfVehicles(Config.greenScreenVehiclePosition.x, Config.greenScreenVehiclePosition.y, Config.greenScreenVehiclePosition.z, 10, false, false, false, false, false)
        Wait(100)

        local function spawnAndScreenshot(vehicleModel)
            local vehicleHash = GetHashKey(vehicleModel)
            if not IsModelValid(vehicleHash) then
                print('[greenscreener] ERROR: Invalid model: ' .. vehicleModel)
                return false
            end

            local vehicleClass = GetVehicleClassFromName(vehicleHash)
            if not Config.includedVehicleClasses[tostring(vehicleClass)] then
                print('[greenscreener] Skipped: ' .. vehicleModel .. ' (class ' .. vehicleClass .. ' not included)')
                SetModelAsNoLongerNeeded(vehicleHash)
                return false
            end

            SendNUIMessage({ type = vehicleModel, value = 1, max = #vehicles + 1 })

            local timeout = GetGameTimer() + Config.vehicleSpawnTimeout
            if not HasModelLoaded(vehicleHash) then
                RequestModel(vehicleHash)
                while not HasModelLoaded(vehicleHash) do
                    Wait(100)
                    if GetGameTimer() > timeout then
                        print('[greenscreener] ERROR: Timeout loading: ' .. vehicleModel)
                        SetModelAsNoLongerNeeded(vehicleHash)
                        return false
                    end
                end
            end

            local vehicle = CreateVehicle(vehicleHash, Config.greenScreenVehiclePosition.x, Config.greenScreenVehiclePosition.y, Config.greenScreenVehiclePosition.z, 0, true, true)

            if not vehicle or vehicle == 0 then
                SetModelAsNoLongerNeeded(vehicleHash)
                print('[greenscreener] ERROR: Could not spawn: ' .. vehicleModel)
                return false
            end

            SetVehicleDirtLevel(vehicle, 0)
            SetEntityRotation(vehicle, Config.greenScreenVehicleRotation.x, Config.greenScreenVehicleRotation.y, Config.greenScreenVehicleRotation.z, 0, false)
            FreezeEntityPosition(vehicle, true)
            SetVehicleWindowTint(vehicle, 1)
            if primarycolor then
                SetVehicleColours(vehicle, primarycolor, secondarycolor or primarycolor)
            end
            Wait(50)

            takeScreenshotForVehicle(vehicle, vehicleHash, vehicleModel)

            DeleteEntity(vehicle)
            SetModelAsNoLongerNeeded(vehicleHash)
            return true
        end

        if vehicleType == 'all' then
            SendNUIMessage({ start = true })
            local successCount = 0
            local failCount = 0
            for _, vehicleModel in ipairs(vehicles) do
                local result = spawnAndScreenshot(vehicleModel)
                if result then
                    successCount = successCount + 1
                else
                    failCount = failCount + 1
                end
            end
            SendNUIMessage({ ["end"] = true })
            print('[greenscreener] Vehicles done: ' .. successCount .. ' success, ' .. failCount .. ' failed, ' .. #vehicles .. ' total')
        else
            spawnAndScreenshot(vehicleType)
        end

        SetPlayerControl(playerId, true)
        startWeatherResource()
        destroyCam()
        RenderScriptCams(false, false, 0, true, false, 0)
    end)
end, false)

RegisterCommand('customscreenshot', function(source, args)
    Citizen.CreateThread(function()
        local component = tonumber(args[1])
        local drawableArg = string.lower(args[2] or '')
        local type = string.upper(args[3] or '')
        local gender = string.lower(args[4] or '')

        local modelHashes = {}
        if gender == 'male' then
            modelHashes = { GetHashKey('mp_m_freemode_01') }
        elseif gender == 'female' then
            modelHashes = { GetHashKey('mp_f_freemode_01') }
        else
            modelHashes = { GetHashKey('mp_m_freemode_01'), GetHashKey('mp_f_freemode_01') }
        end

        if not stopWeatherResource() then return end
        DisableIdleCamera(true)
        Wait(100)

        for _, modelHash in ipairs(modelHashes) do
            if IsModelValid(modelHash) then
                if not HasModelLoaded(modelHash) then
                    RequestModel(modelHash)
                    while not HasModelLoaded(modelHash) do
                        Wait(100)
                    end
                end

                SetPlayerModel(playerId, modelHash)
                Wait(150)
                SetModelAsNoLongerNeeded(modelHash)
                Wait(150)

                ped = PlayerPedId()
                local pedType = modelHash == GetHashKey('mp_m_freemode_01') and 'male' or 'female'

                SetEntityRotation(ped, Config.greenScreenRotation.x, Config.greenScreenRotation.y, Config.greenScreenRotation.z, 0, false)
                SetEntityCoordsNoOffset(ped, Config.greenScreenPosition.x, Config.greenScreenPosition.y, Config.greenScreenPosition.z, false, false, false)
                FreezeEntityPosition(ped, true)
                Wait(50)
                SetPlayerControl(playerId, false)

                resetPedComponents()
                Wait(150)

                if drawableArg == 'all' then
                    SendNUIMessage({ start = true })
                    if type == 'CLOTHING' then
                        local drawableCount = GetNumberOfPedDrawableVariations(ped, component)
                        for drawable = 0, drawableCount - 1 do
                            local texCount = GetNumberOfPedTextureVariations(ped, component, drawable)
                            SendNUIMessage({ type = Config.cameraSettings[type][tostring(component)].name, value = drawable, max = drawableCount })
                            if Config.includeTextures then
                                for texture = 0, texCount - 1 do
                                    loadComponentVariation(component, drawable, texture)
                                    takeScreenshotForComponent(pedType, type, component, drawable, texture)
                                end
                            else
                                loadComponentVariation(component, drawable)
                                takeScreenshotForComponent(pedType, type, component, drawable)
                            end
                        end
                    elseif type == 'PROPS' then
                        local propCount = GetNumberOfPedPropDrawableVariations(ped, component)
                        for prop = 0, propCount - 1 do
                            local texCount = GetNumberOfPedPropTextureVariations(ped, component, prop)
                            SendNUIMessage({ type = Config.cameraSettings[type][tostring(component)].name, value = prop, max = propCount })
                            if Config.includeTextures then
                                for texture = 0, texCount - 1 do
                                    loadPropVariation(component, prop, texture)
                                    takeScreenshotForComponent(pedType, type, component, prop, texture)
                                end
                            else
                                loadPropVariation(component, prop)
                                takeScreenshotForComponent(pedType, type, component, prop)
                            end
                        end
                    end
                else
                    local drawableNum = tonumber(drawableArg)
                    if drawableNum then
                        if type == 'CLOTHING' then
                            local texCount = GetNumberOfPedTextureVariations(ped, component, drawableNum)
                            if Config.includeTextures then
                                for texture = 0, texCount - 1 do
                                    loadComponentVariation(component, drawableNum, texture)
                                    takeScreenshotForComponent(pedType, type, component, drawableNum, texture)
                                end
                            else
                                loadComponentVariation(component, drawableNum)
                                takeScreenshotForComponent(pedType, type, component, drawableNum)
                            end
                        elseif type == 'PROPS' then
                            local texCount = GetNumberOfPedPropTextureVariations(ped, component, drawableNum)
                            if Config.includeTextures then
                                for texture = 0, texCount - 1 do
                                    loadPropVariation(component, drawableNum, texture)
                                    takeScreenshotForComponent(pedType, type, component, drawableNum, texture)
                                end
                            else
                                loadPropVariation(component, drawableNum)
                                takeScreenshotForComponent(pedType, type, component, drawableNum)
                            end
                        end
                    end
                end

                SetPlayerControl(playerId, true)
                FreezeEntityPosition(ped, false)
            end
        end

        setPedOnGround()
        startWeatherResource()
        SendNUIMessage({ ["end"] = true })
        destroyCam()
        RenderScriptCams(false, false, 0, true, false, 0)
        camInfo = nil
    end)
end, false)

-- ============================================
-- Chat suggestions
-- ============================================

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/screenshot', 'Generate clothing screenshots')
    TriggerEvent('chat:addSuggestion', '/screenshotprops', 'Position prop then batch screenshot (E=confirm, Arrows=move, Backspace=cancel)')
    TriggerEvent('chat:addSuggestion', '/screenshotobject', 'Generate object screenshots', {
        { name = 'object', help = 'The object model name or hash' },
    })
    TriggerEvent('chat:addSuggestion', '/screenshotvehicle', 'Generate vehicle screenshots', {
        { name = 'model/all', help = 'Vehicle model name or "all"' },
        { name = 'primarycolor', help = 'Primary vehicle color (optional)' },
        { name = 'secondarycolor', help = 'Secondary vehicle color (optional)' },
    })
    TriggerEvent('chat:addSuggestion', '/customscreenshot', 'Generate custom clothing/prop screenshots', {
        { name = 'component', help = 'The clothing component number' },
        { name = 'drawable/all', help = 'The drawable variation or "all"' },
        { name = 'props/clothing', help = 'PROPS or CLOTHING' },
        { name = 'male/female/both', help = 'The gender' },
    })
end)

-- ============================================
-- Cleanup
-- ============================================

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    startWeatherResource()
    SetPlayerControl(playerId, true)
    if placeMode.active then
        stopPlacementMode()
    end
    if ped then
        FreezeEntityPosition(ped, false)
    end
end)
