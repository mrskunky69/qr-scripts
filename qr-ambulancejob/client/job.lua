isHealingPerson = false
healAnimDict = "mini_games@story@mob4@heal_jules@bandage@arthur"
healAnim = "bandage_fast"
local QRCore = exports['qr-core']:GetCoreObject()

local statusCheckPed = nil
local PlayerJob = {}
local onDuty = false
local currentGarage = 1

-- Functions
local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function GetClosestPlayer()
    local closestPlayers = QRCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end
	return closestPlayer, closestDistance
end

local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)

    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    QRCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetEntityHeading(veh, coords.w)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
	Citizen.InvokeNative(0x400F9556,veh, Lang:t('info.amb_plate')..tostring(math.random(1000, 9999)))
        SetVehicleEngineOn(veh, true, true)
    end, coords, true)
end

function MenuGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[QRCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu+1] = {
            header = label,
            txt = "",
            params = {
                event = "ambulance:client:TakeOutVehicle",
                args = {
                    vehicle = veh
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu+1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = "qr-menu:client:closeMenu"
        }

    }
    exports['qr-menu']:openMenu(vehicleMenu)
end

function createAmbuPrompts()
    for k, v in pairs(Config.Locations["armory"]) do
        exports['qr-core']:createPrompt("ambulance:armory:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Armory', {
            type = 'client',
            event = 'ambulance:client:promptArmory',
        })
    end
    for k, v in pairs(Config.Locations["duty"]) do
        exports['qr-core']:createPrompt("ambulance:duty:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'On/Off Duty', {
            type = 'client',
            event = 'ambulance:client:promptDuty',
        })
    end
    for k, v in pairs(Config.Locations["vehicle"]) do
        exports['qr-core']:createPrompt("ambulance:vehicle:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Jobgarage', {
            type = 'client',
            event = 'ambulance:client:promptVehicle',
            args = {k},
        })
    end
    for k, v in pairs(Config.Locations["stash"]) do
        exports['qr-core']:createPrompt("ambulance:stash:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Personal Stash', {
            type = 'client',
            event = 'ambulance:client:promptStash',
        })
    end
    for k, v in pairs(Config.Locations["beds"]) do
        exports['qr-core']:createPrompt("ambulance:bed:"..k, vector3(Config.Locations["beds"][k].coords.x, Config.Locations["beds"][k].coords.y, Config.Locations["beds"][k].coords.z), Config.PromptKey, Lang:t('text.lie_bed', {cost = Config.BillCost}), {
            type = 'client',
            event = 'ambulance:client:promptBed',
        })
    end
end

-- Events
RegisterNetEvent('ambulance:client:promptArmory', function()
    QRCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
        else
            QRCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)
end)

RegisterNetEvent('ambulance:client:promptDuty', function()
    QRCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            onDuty = not onDuty
            TriggerServerEvent("QRCore:ToggleDuty")
        else
            QRCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)
end)

RegisterNetEvent('ambulance:client:promptVehicle', function(k)
    QRCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        local ped = PlayerPedId()

        if PlayerJob.name == "ambulance"  then
            if IsPedInAnyVehicle(ped, false) then
                QRCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped))
            else
                MenuGarage()
                currentGarage = k
            end
        else
            QRCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)
end)

RegisterNetEvent('ambulance:client:promptStash', function(k)
    QRCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_"..QRCore.Functions.GetPlayerData().citizenid)
            TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_"..QRCore.Functions.GetPlayerData().citizenid)
        else
            QRCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)
end)

RegisterNetEvent('ambulance:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle
    TakeOutVehicle(vehicle)
end)

RegisterNetEvent('QRCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    TriggerServerEvent("hospital:server:SetDoctor")
end)

RegisterNetEvent('QRCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    local ped = PlayerPedId()
    local player = PlayerId()
    TriggerServerEvent("hospital:server:SetDoctor")
    CreateThread(function()
        Wait(5000)
        SetEntityMaxHealth(player, Config.MaxHp)
        SetEntityHealth(player, Config.MaxHp)
        SetPlayerHealthRechargeMultiplier(player, Config.RegenRate)
    end)
    
    CreateThread(function()
        Wait(1000)
        QRCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty
            if (not PlayerData.metadata["inlaststand"] and PlayerData.metadata["isdead"]) then
                deathTime = Laststand.ReviveInterval
                OnDeath()
                DeathTimer()
            elseif (PlayerData.metadata["inlaststand"] and not PlayerData.metadata["isdead"]) then
                SetLaststand(true, true)
            else
                TriggerServerEvent("hospital:server:SetDeathStatus", false)
                TriggerServerEvent("hospital:server:SetLaststandStatus", false)
            end
            createAmbuPrompts()
        end)
    end)
end)

RegisterNetEvent('QRCore:Client:SetDuty', function(duty)
    onDuty = duty
    TriggerServerEvent("hospital:server:SetDoctor")
end)

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        statusCheckPed = GetPlayerPed(player)
        QRCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
                        statusChecks[#statusChecks+1] = {bone = Config.BoneIndexes[k], label = v.label .." (".. Config.WoundStates[v.severity] ..")"}
                    elseif result["WEAPONWOUNDS"] then
                        for k, v in pairs(result["WEAPONWOUNDS"]) do
                            TriggerEvent('chat:addMessage', {
                                color = { 255, 0, 0 },
                                multiline = false,
                                args = { Lang:t('info.status'), QRCore.Shared.Weapons[v2].damagereason }
                            })                        end
                    elseif result["BLEED"] > 0 then
                        TriggerEvent('chat:addMessage', {
                            color = { 255, 0, 0 },
                            multiline = false,
                            args = { Lang:t('info.status'),
                                Lang:t('info.is_status', { status = Config.BleedingStates[v].label }) }
                        })
                    else
						QRCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                    end
                end
                isStatusChecking = true
                statusCheckTime = Config.CheckTime
            end
        end, playerId)
    else
		QRCore.Functions.Notify(Lang:t('error.no_player'), 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    local hasItem = QRCore.Functions.HasItem('firstaid', 1)
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            isHealingPerson = true
            local dict = loadAnimDict('script_re@gold_panner@gold_success')
            TaskPlayAnim(PlayerPedId(), dict, 'SEARCH01', 8.0, 8.0, -1, 1, false, false, false)
            FreezeEntityPosition(PlayerPedId(), true)
            count = 1
            QRCore.Functions.Progressbar("reviving", "Reviving...", 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent("hospital:server:RevivePlayer", playerId)
                FreezeEntityPosition(PlayerPedId(), false)
                count = 0
                --print('I am done')
                isHealingPerson = false
            end)
        else
            QRCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        QRCore.Functions.Notify(Lang:t('error.no_firstaid'), 'error')
    end
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    local hasItem = QRCore.Functions.HasItem('bandage', 1)
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            isHealingPerson = true
            local dict = loadAnimDict('script_re@gold_panner@gold_success')
            TaskPlayAnim(PlayerPedId(), dict, 'SEARCH01', 8.0, 8.0, -1, 1, false, false, false)
            FreezeEntityPosition(PlayerPedId(), true)
            count = 1
            QRCore.Functions.Progressbar("reviving", "Treast Wounds...", 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent("hospital:server:TreatWounds", playerId)
                FreezeEntityPosition(PlayerPedId(), false)
                count = 0
                --print('I am done')
                isHealingPerson = false
            end)
        else
			QRCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
		QRCore.Functions.Notify(Lang:t('error.no_bandage'), 'error')
    end
		
end)

-- Threads
CreateThread(function()
    while true do
        Wait(10)
        if isStatusChecking then
            for k, v in pairs(statusChecks) do
                local x,y,z = table.unpack(GetPedBoneCoords(statusCheckPed, v.bone))
                DrawText3D(x, y, z, v.label)
            end
        end
        if isHealingPerson then
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, healAnimDict, healAnim, 1) then
                loadAnimDict(healAnimDict)
                TaskPlayAnim(ped, healAnimDict, healAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
        end
    end
end)
