local QRCore = exports['qr-core']:GetCoreObject()

Laststand = Laststand or {}
Laststand.ReviveInterval = Config.TimeTillRespawn
Laststand.MinimumRevive = Config.MinimumRevive
InLaststand = false
LaststandTime = 0
isEscorted = false
local isEscorting = false
-- Functions
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

local function LoadAnimation(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(100)
    end
end

function SetLaststand(bool, spawn)
    local ped = PlayerPedId()
    if bool then
        Wait(1000)
        SetEntityHealth(ped, 0)
        InLaststand = true
        TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
        CreateThread(function()
            while InLaststand do
                ped = PlayerPedId()
                player = PlayerId()
                if LaststandTime - 1 > Laststand.MinimumRevive then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= Laststand.MinimumRevive and LaststandTime - 1 ~= 0 then
                    LaststandTime = LaststandTime - 1
                    Config.DeathTime = LaststandTime
                elseif LaststandTime - 1 <= 0 then
					QRCore.Functions.Notify(Lang:t('error.bled_out'), 'error')
					SetLaststand(false)
                    local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(player)
                    local killer = GetPedSourceOfDeath(ped)

                    if killer_2 ~= 0 and killer_2 ~= -1 then
                        killer = killer_2
                    end

                    local killerId = NetworkGetPlayerIndexFromPed(killer)
                    local killerName = killerId ~= -1 and GetPlayerName(killerId) .. " " .. "("..GetPlayerServerId(killerId)..")" or Lang:t('info.self_death')
                    local weaponLabel = Lang:t('info.wep_unknown')
                    local weaponName = Lang:t('info.wep_unknown')
                    local weaponItem = QRCore.Shared.Weapons[killerWeapon]
                    if weaponItem then
                        weaponLabel = weaponItem.label
                        weaponName = weaponItem.name
                    end
                    TriggerServerEvent("qr-log:server:CreateLog", "death", Lang:t('logs.death_log_title', {playername = GetPlayerName(-1), playerid = GetPlayerServerId(player)}), "red", Lang:t('logs.death_log_message', {killername = killerName, playername = GetPlayerName(player), weaponlabel = weaponLabel, weaponname = weaponName}))
                    deathTime = 0
                    OnDeath()
                    DeathTimer()
                end
                Wait(1000)
            end
        end)
    else
        InLaststand = false
        LaststandTime = 0
    end
    TriggerServerEvent("hospital:server:SetLaststandStatus", bool)
end

-- Events
RegisterNetEvent('hospital:client:SetEscortingState', function(bool)
    isEscorting = bool
end)

RegisterNetEvent('hospital:client:isEscorted', function(bool)
    isEscorted = bool
end)

RegisterNetEvent('hospital:client:UseFirstAid', function()
    if not isEscorting then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 1.5 then
            local playerId = GetPlayerServerId(player)
            TriggerServerEvent('hospital:server:UseFirstAid', playerId)
        end
    else
		QRCore.Functions.Notify(Lang:t('error.impossible'), 'error')
    end
end)

RegisterNetEvent('hospital:client:CanHelp', function(helperId)
    if InLaststand then
        if LaststandTime <= 300 then
            TriggerServerEvent('hospital:server:CanHelp', helperId, true)
        else
            TriggerServerEvent('hospital:server:CanHelp', helperId, false)
        end
    else
        TriggerServerEvent('hospital:server:CanHelp', helperId, false)
    end
end)

RegisterNetEvent('hospital:client:HelpPerson', function(targetId)
    local ped = PlayerPedId()
    if lib.progressCircle({
        duration = math.random(30000, 60000),
        position = 'bottom',
        label = Lang:t('progress.revive'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false,
        },
        anim = {
            dict = healAnimDict,
            clip = healAnim,
        },
    })
    then
        ClearPedTasks(ped)
		QRCore.Functions.Notify(Lang:t('success.revived'), 'success')
        TriggerServerEvent("hospital:server:RevivePlayer", targetId)
    else
        ClearPedTasks(ped)
		QRCore.Functions.Notify(Lang:t('error.canceled'), 'error')
        lib.notify({
            id = 'canceled',
            title = Lang:t('error.canceled'),
            duration = 2500,
            style = {
                backgroundColor = '#141517',
                color = '#ffffff'
            },
            icon = 'xmark',
            iconColor = '#C0392B'
        })
    end
end)
