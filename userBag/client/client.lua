local RSGCore = exports['rsg-core']:GetCoreObject()

local ObjectList = {}

RegisterNetEvent('Bag:Client:SpawnAmbulanceBag', function(objectId, type, player)
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(player)))
    local heading = GetEntityHeading(GetPlayerPed(GetPlayerFromServerId(player)))
    local forward = GetEntityForwardVector(PlayerPedId())
    local x, y, z = table.unpack(coords + forward * 0.5)
    local spawnedObj = CreateObject(Config.Bag.AmbulanceBag[type].model, x, y, coords.z-1, true, false, false)
    PlaceObjectOnGroundProperly(spawnedObj)
    SetEntityHeading(spawnedObj, heading)
    FreezeEntityPosition(spawnedObj, Config.Bag.AmbulanceBag[type].freeze)
    ObjectList[objectId] = {
        id = objectId,
        object = spawnedObj,
        coords = vector3(x, y, z - 0.3),
    }
    TriggerServerEvent("Bag:Server:RemoveItem","bag",1)
end)

RegisterNetEvent('Bag:Client:spawnLight', function()
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CROUCH_INSPECT")
    progressBar("Placing the  Bag...")
    Wait(2500)
    TriggerServerEvent("Bag:Server:SpawnAmbulanceBag", "bag")
end)

RegisterNetEvent('Bag:Client:GuardarAmbulanceBag')
AddEventHandler("Bag:Client:GuardarAmbulanceBag", function()
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))
    local playerPedPos = GetEntityCoords(PlayerPedId(), true)
    local AmbulanceBag = GetClosestObjectOfType(playerPedPos, 10.0, GetHashKey("s_knapsack01x"), false, false, false)
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CROUCH_INSPECT")
    progressBar("Taking Back the Bag...")
    Wait(2500)
    Notify("Bag Taken Back with success.")
    SetEntityAsMissionEntity(AmbulanceBag, 1, 1)
    DeleteObject(AmbulanceBag)
    TriggerServerEvent("Bag:Server:AddItem","bag",1)
end)

local citizenid = nil
AddEventHandler("Bag:Client:StorageAmbulanceBag", function()
    local charinfo = RSGCore.Functions.GetPlayerData().charinfo
    citizenid = RSGCore.Functions.GetPlayerData().citizenid
    TriggerEvent("inventory:client:SetCurrentStash", " Bag",citizenid)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", " Bag",citizenid, {
        maxweight = 40000,
        slots = 48,
    })
end)

local AmbulanceBags = {
    `s_knapsack01x`,
}

exports['rsg-target']:AddTargetModel(AmbulanceBags, {
    options = {{event   = "Bag:Client:MenuAmbulanceBag",icon    = "fa-solid fa-briefcase",label   = "Bag"},
    {event   = "Bag:Client:GuardarAmbulanceBag",icon    = "fa-solid fa-briefcase",label   = "Take Back Bag"},},distance = 2.0 })