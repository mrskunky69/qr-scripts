local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent('badge:open')
AddEventHandler('badge:open', function(ID, targetID, type)
	local Player = QRCore.Functions.GetPlayer(ID)

	local data = {
		name = Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname,
		dob = Player.PlayerData.charinfo.dob
	}

	TriggerClientEvent('badge:open', targetID, data)
	TriggerClientEvent( 'badge:shot', targetID, source )
end)

QRCore.Functions.CreateUseableItem('specialbadge', function(source, item)
    TriggerClientEvent('badge:openPD', source, true)
end)