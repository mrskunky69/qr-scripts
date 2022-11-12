local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent('qr-bushes:addbushes')
AddEventHandler('qr-bushes:addbushes', function() 
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
	local randomNumber = math.random(1,100)

	if randomNumber > 0 and randomNumber <= 70 then
		local _subRan = math.random(1,5)
			if _subRan == 1 then
				Player.Functions.AddItem('carrot', givecarrot)
				TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['carrot'], "add")
				TriggerClientEvent('QRCore:Notify', src, 'you found a carrot')
			elseif _subRan == 3 then
				Player.Functions.AddItem('lettuceseed', givelettuceseed)
				TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['lettuceseed'], "add")
				TriggerClientEvent('QRCore:Notify', src, 'you found lettuceseeds')
			elseif _subRan == 4 then
				Player.Functions.AddItem('wheatseed', givewheatseed)
				TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['wheatseed'], "add")
				TriggerClientEvent('QRCore:Notify', src, 'you found wheatseed')
			else
			TriggerClientEvent('QRCore:Notify', src, 'you failed to find anything')
		end

	elseif randomNumber > 70 and randomNumber <= 100 then
		local _subRan = math.random(1,4)
			if _subRan == 1 then
				Player.Functions.AddItem('sugarseed', givewheatseed)
				TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['sugarseed'], "add")
				TriggerClientEvent('QRCore:Notify', src, 'you found sugarseed')
			elseif _subRan == 2 then
				Player.Functions.AddItem('corn', givewheatseed)
				TriggerClientEvent('inventory:client:ItemBox', src, QRCore.Shared.Items['corn'], "add")
				TriggerClientEvent('QRCore:Notify', src, 'you found corn')
			else
				TriggerClientEvent('QRCore:Notify', src, 'you failed to find anything')
			end
		end
	end)

