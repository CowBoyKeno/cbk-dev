local state = {
    menuOpen = false,
    playerGod = false,
    vehicleGod = false,
    noReload = false,
    invisible = false,
    infiniteStamina = false,
    superJump = false,
    neverWanted = false,
    noclip = false,
    blackout = false,
    freezeTime = false,
    currentWeather = 'CLEAR',
    timeHour = 12,
    timeMinute = 0
}

local currentNoclipSpeed = Config.NoclipSpeed
local cachedVehicle = 0

local function setVehicleProtection(vehicle, enabled)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    SetEntityInvincible(vehicle, enabled)
    SetVehicleCanBreak(vehicle, not enabled)
    SetVehicleTyresCanBurst(vehicle, not enabled)
    SetVehicleWheelsCanBreak(vehicle, not enabled)

    if enabled then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        cachedVehicle = vehicle
    end
end

local function getClosestUsableVehicle(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestVehicle = 0
    local closestDistance = radius or 8.0

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle) then
            local distance = #(coords - GetEntityCoords(vehicle))
            if distance < closestDistance then
                closestVehicle = vehicle
                closestDistance = distance
            end
        end
    end

    return closestVehicle
end

local function getTargetVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        cachedVehicle = vehicle
        return vehicle
    end

    if cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
        return cachedVehicle
    end

    return getClosestUsableVehicle(8.0)
end

local function notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function drawText(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(text)
    DrawText(x, y)
end

local function rotationToDirection(rotation)
    local adjustedX = math.rad(rotation.x)
    local adjustedZ = math.rad(rotation.z)
    local cosX = math.abs(math.cos(adjustedX))
    return vector3(-math.sin(adjustedZ) * cosX, math.cos(adjustedZ) * cosX, math.sin(adjustedX))
end

local function requestModel(model)
    local modelHash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        return nil, 'Invalid vehicle model'
    end

    RequestModel(modelHash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(modelHash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return nil, 'Model load timed out'
        end
    end

    return modelHash
end

local function getControlledEntity()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) == ped then
            return veh, true
        end
    end
    return ped, false
end

local function getVehicleEntity()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        notify('~r~No vehicle found.')
        return nil
    end
    return veh
end

local function getVehicleModName(modType)
    return Config.VehicleModTypeLabels[modType] or ('Mod Slot #' .. tostring(modType))
end

local function getVehicleModOptionLabel(vehicle, modType, optionIndex)
    if not vehicle or optionIndex == nil then
        return ('Option %d'):format(optionIndex + 1)
    end

    local label = GetModTextLabel(vehicle, modType, optionIndex)
    if label and label ~= '' and label ~= 'NULL' then
        local display = GetLabelText(label)
        if display and display ~= '' and display ~= 'NULL' then
            return display
        end
        return label
    end

    return ('Option %d'):format(optionIndex + 1)
end

local function buildVehicleModData(vehicle)
    local modData = {
        mods = {},
        extras = {},
        windowTint = GetVehicleWindowTint(vehicle),
        windowTintOptions = Config.VehicleWindowTintLabels,
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        plateIndexOptions = Config.VehiclePlateIndexLabels,
        neon = {
            left = IsVehicleNeonLightEnabled(vehicle, 0),
            right = IsVehicleNeonLightEnabled(vehicle, 1),
            front = IsVehicleNeonLightEnabled(vehicle, 2),
            back = IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = { 0, 0, 0 },
        livery = nil,
    }

    local r, g, b = GetVehicleNeonLightsColour(vehicle)
    if r and g and b then
        modData.neonColor = { r = r, g = g, b = b }
    end

    for modType = 0, 49 do
        local count = GetNumVehicleMods(vehicle, modType)
        if count and count > 0 then
            local options = {
                { label = 'Stock / Remove', value = -1 }
            }
            for optionIndex = 0, count - 1 do
                options[#options + 1] = {
                    label = getVehicleModOptionLabel(vehicle, modType, optionIndex),
                    value = optionIndex
                }
            end
            modData.mods[#modData.mods + 1] = {
                type = modType,
                name = getVehicleModName(modType),
                current = GetVehicleMod(vehicle, modType),
                options = options
            }
        end
    end

    local liveryCount = GetVehicleLiveryCount(vehicle)
    if liveryCount and liveryCount > 0 then
        local options = {}
        for i = 0, liveryCount - 1 do
            options[#options + 1] = {
                label = ('Livery %d'):format(i),
                value = i
            }
        end
        modData.livery = {
            current = GetVehicleLivery(vehicle),
            options = options
        }
    end

    for extra = 0, 20 do
        if DoesExtraExist(vehicle, extra) then
            modData.extras[#modData.extras + 1] = {
                index = extra,
                name = ('Extra %d'):format(extra),
                enabled = IsVehicleExtraTurnedOn(vehicle, extra)
            }
        end
    end

    return modData
end

local function applyVehicleMod(vehicle, modType, modIndex)
    if not vehicle or modType == nil or modIndex == nil then
        return false
    end

    SetVehicleModKit(vehicle, 0)
    if modIndex == -1 then
        RemoveVehicleMod(vehicle, modType)
    else
        SetVehicleMod(vehicle, modType, modIndex, false)
    end
    return true
end

local function applyVehicleTint(vehicle, tintIndex)
    if not vehicle or tintIndex == nil then
        return false
    end
    SetVehicleWindowTint(vehicle, tintIndex)
    return true
end

local function applyVehicleLivery(vehicle, liveryIndex)
    if not vehicle or liveryIndex == nil then
        return false
    end
    SetVehicleLivery(vehicle, liveryIndex)
    return true
end

local function applyVehiclePlate(vehicle, plateIndex)
    if not vehicle or plateIndex == nil then
        return false
    end
    SetVehicleNumberPlateTextIndex(vehicle, plateIndex)
    return true
end

local function toggleVehicleExtra(vehicle, extraIndex, enabled)
    if not vehicle or extraIndex == nil then
        return false
    end
    if DoesExtraExist(vehicle, extraIndex) then
        SetVehicleExtra(vehicle, extraIndex, enabled and 0 or 1)
        return true
    end
    return false
end

local function setNeonLight(vehicle, slot, enabled)
    if not vehicle or slot == nil then
        return false
    end
    SetVehicleNeonLightEnabled(vehicle, slot, enabled and true or false)
    return true
end

local function setNeonColor(vehicle, r, g, b)
    if not vehicle or r == nil or g == nil or b == nil then
        return false
    end
    SetVehicleNeonLightsColour(vehicle, r, g, b)
    return true
end

local function setMenu(open)
    state.menuOpen = open
    SetNuiFocus(open, open)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = open and 'open' or 'close',
        title = Config.MenuTitle
    })
    if open then
        SendNUIMessage({
            action = 'setState',
            data = state
        })
    end
end

local function applyWeather()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(state.currentWeather)
    SetWeatherTypeNow(state.currentWeather)
    SetOverrideWeather(state.currentWeather)
    notify(('~b~Weather: ~w~%s'):format(state.currentWeather))
end

local function applyTime()
    NetworkOverrideClockTime(state.timeHour, state.timeMinute, 0)
    notify(('~b~Time: ~w~%02d:%02d'):format(state.timeHour, state.timeMinute))
end

local function repairVehicle(vehicle)
    if vehicle == 0 then
        notify('~r~No vehicle found.')
        return
    end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    for i = 0, 7 do
        SetVehicleTyreFixed(vehicle, i)
    end
    notify('~g~Vehicle repaired.')
end

local function maxVehicle(vehicle)
    if vehicle == 0 then
        notify('~r~No vehicle found.')
        return
    end

    SetVehicleModKit(vehicle, 0)
    for i = 0, 49 do
        local count = GetNumVehicleMods(vehicle, i)
        if count and count > 0 then
            SetVehicleMod(vehicle, i, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 20, true)
    ToggleVehicleMod(vehicle, 22, true)
    SetVehicleWindowTint(vehicle, 1)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleNumberPlateTextIndex(vehicle, 1)
    SetVehicleDirtLevel(vehicle, 0.0)
    notify('~g~Vehicle maxed.')
end

local function spawnVehicle(modelName)
    if not modelName or modelName == '' then
        notify('~r~Enter a vehicle model.')
        return
    end

    local model = requestModel(modelName:lower())
    if not model then
        notify('~r~Failed to load model: ' .. tostring(modelName))
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)

    local vehicle = CreateVehicle(model, coords.x + forward.x * 5.0, coords.y + forward.y * 5.0, coords.z + 1.0, heading, true, false)
    if vehicle == 0 then
        SetModelAsNoLongerNeeded(model)
        notify('~r~Vehicle spawn failed.')
        return
    end

    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(model)
    cachedVehicle = vehicle
    if state.vehicleGod then
        setVehicleProtection(vehicle, true)
    end
    repairVehicle(vehicle)
    notify('~g~Spawned vehicle: ~w~' .. modelName:lower())
end

local function giveAllWeapons()
    local ped = PlayerPedId()
    for _, weaponName in ipairs(Config.Weapons) do
        local weaponHash = joaat(weaponName)
        local ammo = Config.AmmoByWeapon[weaponName] or Config.AmmoByWeapon.default
        GiveWeaponToPed(ped, weaponHash, ammo, false, false)
        SetPedAmmo(ped, weaponHash, ammo)
    end
    notify('~g~All configured weapons added.')
end

local function refillAmmo()
    local ped = PlayerPedId()
    for _, weaponName in ipairs(Config.Weapons) do
        local weaponHash = joaat(weaponName)
        local ammo = Config.AmmoByWeapon[weaponName] or Config.AmmoByWeapon.default
        if HasPedGotWeapon(ped, weaponHash, false) then
            SetPedAmmo(ped, weaponHash, ammo)
        end
    end
    notify('~g~Ammo refilled.')
end

local function removeWeapons()
    RemoveAllPedWeapons(PlayerPedId(), true)
    notify('~y~All weapons removed.')
end

local function healPlayer()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
    ClearPlayerWantedLevel(PlayerId())
    notify('~g~Player healed and armour restored.')
end

local function flipVehicle(vehicle)
    if vehicle == 0 then
        notify('~r~No vehicle found.')
        return
    end

    local coords = GetEntityCoords(vehicle)
    SetEntityCoords(vehicle, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
    SetEntityRotation(vehicle, 0.0, 0.0, GetEntityHeading(vehicle), 2, true)
    SetVehicleOnGroundProperly(vehicle)
    notify('~g~Vehicle flipped.')
end

local function deleteVehicle(vehicle)
    if vehicle == 0 then
        notify('~r~No vehicle found.')
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
    if cachedVehicle == vehicle then
        cachedVehicle = 0
    end
    notify('~g~Vehicle deleted.')
end

local function teleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        notify('~r~Place a waypoint first.')
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local entity, isVehicle = getControlledEntity()

    for height = 1, 1000 do
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, height + 0.0, false, false, false)
        RequestCollisionAtCoord(coords.x, coords.y, height + 0.0)
        local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, height + 0.0, false)
        if foundGround then
            SetEntityCoordsNoOffset(entity, coords.x, coords.y, groundZ + (isVehicle and 1.0 or 0.5), false, false, false)
            if isVehicle then
                SetVehicleOnGroundProperly(entity)
            end
            notify('~g~Teleported to waypoint.')
            return
        end
        Wait(5)
    end

    SetEntityCoordsNoOffset(entity, coords.x, coords.y, 1000.0, false, false, false)
    notify('~y~Teleported high above waypoint; ground not found.')
end

local function setNoclipEnabled(enabled)
    state.noclip = enabled
    local entity = getControlledEntity()
    local playerPed = PlayerPedId()
    local isPlayerPed = entity == playerPed
    SetEntityCollision(entity, not enabled, not enabled)
    FreezeEntityPosition(entity, enabled)
    SetEntityInvincible(entity, enabled or (isPlayerPed and state.playerGod) or ((not isPlayerPed) and state.vehicleGod))
    SetEntityVisible(entity, not state.invisible, false)
    if enabled then
        notify('~b~Noclip enabled.')
    else
        FreezeEntityPosition(entity, false)
        SetEntityCollision(entity, true, true)
        notify('~b~Noclip disabled.')
    end
end

local function gatherStatus()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local vehModel = veh ~= 0 and GetEntityModel(veh) or 0
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or ''
    local area = street
    if crossing ~= '' then
        area = area .. ' / ' .. crossing
    end

    return {
        playerGod = state.playerGod,
        vehicleGod = state.vehicleGod,
        noReload = state.noReload,
        invisible = state.invisible,
        infiniteStamina = state.infiniteStamina,
        superJump = state.superJump,
        neverWanted = state.neverWanted,
        noclip = state.noclip,
        blackout = state.blackout,
        freezeTime = state.freezeTime,
        currentWeather = state.currentWeather,
        timeHour = state.timeHour,
        timeMinute = state.timeMinute,
        coords = {
            x = math.floor(coords.x * 100.0 + 0.5) / 100.0,
            y = math.floor(coords.y * 100.0 + 0.5) / 100.0,
            z = math.floor(coords.z * 100.0 + 0.5) / 100.0,
            h = math.floor(heading * 100.0 + 0.5) / 100.0
        },
        area = area,
        inVehicle = veh ~= 0,
        vehicleModel = veh ~= 0 and vehModel or nil,
        vehicleName = veh ~= 0 and GetDisplayNameFromVehicleModel(vehModel) or nil
    }
end

RegisterNUICallback('close', function(_, cb)
    setMenu(false)
    cb({ ok = true })
end)

RegisterNUICallback('toggle', function(data, cb)
    local key = data and data.key or nil
    if key and state[key] ~= nil then
        state[key] = not state[key]
        local shouldNotify = true

        if key == 'invisible' then
            SetEntityVisible(PlayerPedId(), not state.invisible, false)
        elseif key == 'playerGod' then
            SetPlayerInvincible(PlayerId(), state.playerGod)
            SetEntityInvincible(PlayerPedId(), state.playerGod)
        elseif key == 'vehicleGod' then
            local vehicle = getTargetVehicle()
            if vehicle ~= 0 then
                setVehicleProtection(vehicle, state.vehicleGod)
            elseif not state.vehicleGod and cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
                setVehicleProtection(cachedVehicle, false)
                cachedVehicle = 0
            end
        elseif key == 'noclip' then
            setNoclipEnabled(state.noclip)
            shouldNotify = false
            if state.noclip and state.menuOpen then
                setMenu(false)
            end
        elseif key == 'blackout' then
            SetArtificialLightsState(state.blackout)
            SetArtificialLightsStateAffectsVehicles(false)
        elseif key == 'freezeTime' then
            PauseClock(state.freezeTime)
            if state.freezeTime then
                NetworkOverrideClockTime(state.timeHour, state.timeMinute, 0)
            end
        end

        SendNUIMessage({ action = 'setState', data = state })
        if shouldNotify then
            notify(('~b~%s: ~w~%s'):format(key, state[key] and 'ON' or 'OFF'))
        end
    end

    cb({ ok = true, state = state })
end)

RegisterNUICallback('action', function(data, cb)
    local name = data and data.name or ''
    if name == 'heal' then
        healPlayer()
    elseif name == 'tp_waypoint' then
        teleportToWaypoint()
    elseif name == 'spawn_vehicle' then
        spawnVehicle(data.value or '')
    elseif name == 'repair_vehicle' then
        repairVehicle(getTargetVehicle())
    elseif name == 'clean_vehicle' then
        local veh = getTargetVehicle()
        if veh ~= 0 then
            SetVehicleDirtLevel(veh, 0.0)
            notify('~g~Vehicle cleaned.')
        else
            notify('~r~No vehicle found.')
        end
    elseif name == 'flip_vehicle' then
        flipVehicle(getTargetVehicle())
    elseif name == 'delete_vehicle' then
        deleteVehicle(getTargetVehicle())
    elseif name == 'max_vehicle' then
        maxVehicle(getTargetVehicle())
    elseif name == 'engine_toggle' then
        local veh = getTargetVehicle()
        if veh ~= 0 then
            local running = GetIsVehicleEngineRunning(veh)
            SetVehicleEngineOn(veh, not running, true, true)
            notify(('~b~Vehicle engine: ~w~%s'):format((not running) and 'ON' or 'OFF'))
        else
            notify('~r~No vehicle found.')
        end
    elseif name == 'give_weapons' then
        giveAllWeapons()
    elseif name == 'refill_ammo' then
        refillAmmo()
    elseif name == 'remove_weapons' then
        removeWeapons()
    elseif name == 'set_weather' then
        local weather = tostring(data.value or 'CLEAR'):upper()
        state.currentWeather = weather
        applyWeather()
    elseif name == 'set_time' or name == 'set_time_preset' or name == 'set_time_custom' then
        local hour = tonumber(data.hour)
        local minute = tonumber(data.minute)
        if hour == nil or minute == nil then
            notify('~r~Invalid time.')
        else
            state.timeHour = math.max(0, math.min(23, math.floor(hour)))
            state.timeMinute = math.max(0, math.min(59, math.floor(minute)))
            applyTime()
            if state.freezeTime then
                PauseClock(true)
            end
        end
    elseif name == 'set_vehicle_mod' then
        local veh = getVehicleEntity()
        local modType = tonumber(data.modType)
        local modIndex = tonumber(data.modIndex)
        if veh and modType then
            if applyVehicleMod(veh, modType, modIndex) then
                notify(('~g~Applied %s to vehicle.'):format(getVehicleModName(modType)))
            else
                notify('~r~Failed to apply vehicle mod.')
            end
        end
    elseif name == 'toggle_vehicle_extra' then
        local veh = getVehicleEntity()
        local extraIndex = tonumber(data.extraIndex)
        if veh and extraIndex then
            local enabled = data.enabled == true
            if toggleVehicleExtra(veh, extraIndex, enabled) then
                notify(('~g~Extra %s %s.'):format(extraIndex, enabled and 'enabled' or 'disabled'))
            else
                notify('~r~Failed to toggle vehicle extra.')
            end
        end
    elseif name == 'set_window_tint' then
        local veh = getVehicleEntity()
        local tintIndex = tonumber(data.tintIndex)
        if veh and tintIndex ~= nil then
            if applyVehicleTint(veh, tintIndex) then
                notify(('~g~Window tint set to %s.'):format(Config.VehicleWindowTintLabels[tintIndex] or tostring(tintIndex)))
            else
                notify('~r~Failed to set window tint.')
            end
        end
    elseif name == 'set_livery' then
        local veh = getVehicleEntity()
        local liveryIndex = tonumber(data.liveryIndex)
        if veh and liveryIndex then
            if applyVehicleLivery(veh, liveryIndex) then
                notify(('~g~Livery set to %d.'):format(liveryIndex))
            else
                notify('~r~Failed to set livery.')
            end
        end
    elseif name == 'set_plate_index' then
        local veh = getVehicleEntity()
        local plateIndex = tonumber(data.plateIndex)
        if veh and plateIndex ~= nil then
            if applyVehiclePlate(veh, plateIndex) then
                notify(('~g~Plate index set to %s.'):format(Config.VehiclePlateIndexLabels[plateIndex] or tostring(plateIndex)))
            else
                notify('~r~Failed to set plate index.')
            end
        end
    elseif name == 'toggle_neon' then
        local veh = getVehicleEntity()
        local slot = tonumber(data.neonSlot)
        local enabled = data.enabled == true
        if veh and slot ~= nil then
            if setNeonLight(veh, slot, enabled) then
                notify(('~g~Neon %s %s.'):format(slot, enabled and 'enabled' or 'disabled'))
            else
                notify('~r~Failed to toggle neon.')
            end
        end
    elseif name == 'set_neon_color' then
        local veh = getVehicleEntity()
        local r = tonumber(data.r)
        local g = tonumber(data.g)
        local b = tonumber(data.b)
        if veh and r and g and b then
            if setNeonColor(veh, math.max(0, math.min(255, r)), math.max(0, math.min(255, g)), math.max(0, math.min(255, b))) then
                notify(('~g~Neon color set to R:%d G:%d B:%d.'):format(r, g, b))
            else
                notify('~r~Failed to set neon color.')
            end
        else
            notify('~r~Invalid neon color.')
        end
    elseif name == 'copy_coords' then
        SendNUIMessage({
            action = 'copyCoords',
            text = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(
                GetEntityCoords(PlayerPedId()).x,
                GetEntityCoords(PlayerPedId()).y,
                GetEntityCoords(PlayerPedId()).z,
                GetEntityHeading(PlayerPedId())
            )
        })
    end

    cb({ ok = true, state = gatherStatus() })
end)

RegisterNUICallback('getStatus', function(_, cb)
    cb(gatherStatus())
end)

RegisterNUICallback('getVehicleMods', function(_, cb)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        cb({ ok = false, error = 'no_vehicle' })
        return
    end
    cb({ ok = true, data = buildVehicleModData(veh) })
end)

RegisterCommand(Config.KeybindCommand, function()
    setMenu(not state.menuOpen)
end, false)

RegisterKeyMapping(Config.KeybindCommand, Config.KeybindDescription, 'keyboard', Config.DefaultKey)

CreateThread(function()
    applyWeather()
    applyTime()

    while true do
        local waitTime = 500

        if state.playerGod then
            local ped = PlayerPedId()
            SetPlayerInvincible(PlayerId(), true)
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, false)
            SetEntityProofs(ped, true, true, true, true, true, true, true, true)
        else
            SetPedCanRagdoll(PlayerPedId(), true)
            SetEntityProofs(PlayerPedId(), false, false, false, false, false, false, false, false)
        end

        if state.vehicleGod then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                setVehicleProtection(veh, true)
            elseif cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
                setVehicleProtection(cachedVehicle, true)
            end
        elseif cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
            setVehicleProtection(cachedVehicle, false)
            cachedVehicle = 0
        end

        if state.noReload then
            local ped = PlayerPedId()
            SetPedInfiniteAmmoClip(ped, true)
            local _, weaponHash = GetCurrentPedWeapon(ped, true)
            if weaponHash and weaponHash ~= 0 then
                SetPedAmmo(ped, weaponHash, 9999)
            end
        else
            SetPedInfiniteAmmoClip(PlayerPedId(), false)
        end

        if state.infiniteStamina then
            RestorePlayerStamina(PlayerId(), 1.0)
        end

        if state.superJump then
            SetSuperJumpThisFrame(PlayerId())
        end

        if state.neverWanted then
            ClearPlayerWantedLevel(PlayerId())
            SetMaxWantedLevel(0)
        else
            SetMaxWantedLevel(5)
        end

        if state.freezeTime then
            NetworkOverrideClockTime(state.timeHour, state.timeMinute, 0)
        end

        if state.blackout then
            SetArtificialLightsState(true)
            SetArtificialLightsStateAffectsVehicles(false)
        end

        if state.noclip then
            waitTime = 0
            local entity = getControlledEntity()
            local camRot = GetGameplayCamRot(2)
            local camDir = rotationToDirection(camRot)
            local pos = GetEntityCoords(entity)
            local speed = currentNoclipSpeed

            if IsDisabledControlPressed(0, 21) then
                speed = speed * Config.NoclipFastMultiplier
            elseif IsDisabledControlPressed(0, 36) then
                speed = speed * Config.NoclipSlowMultiplier
            end

            if IsDisabledControlPressed(0, 32) then
                pos = pos + camDir * speed
            end
            if IsDisabledControlPressed(0, 33) then
                pos = pos - camDir * speed
            end

            local rightDir = vector3(camDir.y, -camDir.x, 0.0)
            if IsDisabledControlPressed(0, 34) then
                pos = pos - rightDir * speed
            end
            if IsDisabledControlPressed(0, 35) then
                pos = pos + rightDir * speed
            end
            if IsDisabledControlPressed(0, 44) then
                pos = pos + vector3(0.0, 0.0, speed)
            end
            if IsDisabledControlPressed(0, 38) then
                pos = pos - vector3(0.0, 0.0, speed)
            end

            SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)
            SetEntityHeading(entity, GetGameplayCamRot(2).z)

            HideHudAndRadarThisFrame()
            drawText(0.015, 0.78, ('Noclip | Speed %.2f'):format(speed), 0.35)
            drawText(0.015, 0.805, 'W/S Forward/Back | A/D Left/Right | Q/E Up/Down | Shift Fast | Ctrl Slow | ESC Exit', 0.30)

            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)

            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) then
                setNoclipEnabled(false)
            end
        end

        Wait(waitTime)
    end
end)

CreateThread(function()
    while true do
        if state.menuOpen then
            SendNUIMessage({
                action = 'status',
                data = gatherStatus()
            })
            Wait(Config.OpenStatusRefreshMs)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetPedInfiniteAmmoClip(PlayerPedId(), false)
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(PlayerPedId(), false)
    SetPedCanRagdoll(PlayerPedId(), true)
    SetEntityProofs(PlayerPedId(), false, false, false, false, false, false, false, false)
    SetMaxWantedLevel(5)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetArtificialLightsState(false)
    PauseClock(false)

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)

    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetEntityInvincible(veh, false)
        SetVehicleCanBreak(veh, true)
        SetVehicleTyresCanBurst(veh, true)
        SetVehicleWheelsCanBreak(veh, true)
    end

    if cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
        setVehicleProtection(cachedVehicle, false)
    end
end)
