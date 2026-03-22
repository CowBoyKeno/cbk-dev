
local state = {
    menuOpen = false,
    playerGod = false,
    vehicleGod = false,
    noReload = false,
    invisible = false,
    infiniteStamina = false,
    superJump = false,
    neverWanted = false,
    noclip = false
}

local currentNoclipSpeed = Config.NoclipSpeed
local cachedVehicle = 0

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
    notify('~g~Vehicle deleted.')
end

local function teleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        notify('~r~Place a waypoint first.')
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()
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
    SetEntityCollision(entity, not enabled, not enabled)
    FreezeEntityPosition(entity, enabled)
    SetEntityInvincible(entity, enabled or (entity ~= PlayerPedId() and state.vehicleGod))
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

        if key == 'invisible' then
            SetEntityVisible(PlayerPedId(), not state.invisible, false)
        elseif key == 'playerGod' then
            SetPlayerInvincible(PlayerId(), state.playerGod)
            SetEntityInvincible(PlayerPedId(), state.playerGod)
        elseif key == 'noclip' then
            setNoclipEnabled(state.noclip)
        end

        SendNUIMessage({ action = 'setState', data = state })
        notify(('~b~%s: ~w~%s'):format(key, state[key] and 'ON' or 'OFF'))
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
        repairVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    elseif name == 'clean_vehicle' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then
            SetVehicleDirtLevel(veh, 0.0)
            notify('~g~Vehicle cleaned.')
        else
            notify('~r~No vehicle found.')
        end
    elseif name == 'flip_vehicle' then
        flipVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    elseif name == 'delete_vehicle' then
        deleteVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    elseif name == 'max_vehicle' then
        maxVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    elseif name == 'engine_toggle' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
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

    cb({ ok = true })
end)

RegisterNUICallback('getStatus', function(_, cb)
    cb(gatherStatus())
end)

RegisterCommand(Config.KeybindCommand, function()
    setMenu(not state.menuOpen)
end, false)

RegisterKeyMapping(Config.KeybindCommand, Config.KeybindDescription, 'keyboard', Config.DefaultKey)

CreateThread(function()
    while true do
        local waitTime = 500

        if state.playerGod then
            local ped = PlayerPedId()
            SetPlayerInvincible(PlayerId(), true)
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, false)
            SetEntityProofs(ped, true, true, true, true, true, true, true, true)
        end

        if state.vehicleGod then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                SetEntityInvincible(veh, true)
                SetVehicleCanBreak(veh, false)
                SetVehicleTyresCanBurst(veh, false)
                SetVehicleWheelsCanBreak(veh, false)
                SetVehicleFixed(veh)
                SetVehicleDeformationFixed(veh)
                cachedVehicle = veh
            elseif cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
                SetEntityInvincible(cachedVehicle, true)
                SetVehicleCanBreak(cachedVehicle, false)
                SetVehicleTyresCanBurst(cachedVehicle, false)
                SetVehicleWheelsCanBreak(cachedVehicle, false)
            end
        elseif cachedVehicle ~= 0 and DoesEntityExist(cachedVehicle) then
            SetEntityInvincible(cachedVehicle, false)
            SetVehicleCanBreak(cachedVehicle, true)
            SetVehicleTyresCanBurst(cachedVehicle, true)
            SetVehicleWheelsCanBreak(cachedVehicle, true)
            cachedVehicle = 0
        end

        if state.noReload then
            local ped = PlayerPedId()
            SetPedInfiniteAmmoClip(ped, true)
            DisablePlayerFiring(PlayerId(), false)
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

        if state.noclip then
            waitTime = 0
            local entity, _ = getControlledEntity()
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
            drawText(0.015, 0.805, 'W/S Forward/Back | A/D Left/Right | Q/E Up/Down | Shift Fast | Ctrl Slow', 0.30)

            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 36, true)
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
    SetMaxWantedLevel(5)

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
end)
