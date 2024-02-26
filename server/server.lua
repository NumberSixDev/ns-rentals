local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ns-rentals:server:PayForRental', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        print("Player Data Not Found")
        return
    end
    
    local cashBalance = Player.PlayerData.money["cash"]
    local bankBalance = Player.PlayerData.money["bank"]
    local rentalPrice = 500
    
    if cashBalance >= rentalPrice then
        Player.Functions.RemoveMoney("cash", rentalPrice, "paid-rental")
    elseif bankBalance >= rentalPrice then
        Player.Functions.RemoveMoney("bank", rentalPrice, "paid-rental")
    else
        QBCore.Functions.Notify("You cannot afford to rent a vehicle", "primary", 5000)
    end
    
    GiveVehiclePapers(src)
end)

function GiveVehiclePapers(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        print("Player Data Not Found")
        return
    end

    local vehicle = GetVehiclePedIsIn(Player.PlayerPed, false)
    local numberplate = GetVehicleNumberPlateText(vehicle)

    local info = {
        temporaryOwner = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid = Player.PlayerData.citizenid,
        vehicleModel = GetEntityModel(vehicle), -- Use GetEntityModel to get the model of the vehicle
        plate = numberplate
    }

    Player.Functions.AddItem('rentalpapers', 1, true, info)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['rentalpapers'], "add")
end

RegisterNetEvent('ns-rentals:server:GivePapers', function(source)
    local src = source
    GiveVehiclePapers(src)
end)

RegisterNetEvent('ns-rentals:server:removepapers', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.RemoveItem('rentalpapers', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['rentalpapers'], "remove")
        Player.Functions.AddMoney("cash", Config.RentalReturn, "rental-compensation")
    end
end)

QBCore.Functions.CreateUseableItem("rentalpapers", function(source, item)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)

    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local targetPlayerPed = GetPlayerPed(v)
        local targetPlayerCoords = GetEntityCoords(targetPlayerPed)
        local dist = #(playerCoords - targetPlayerCoords)

        if dist < 3.0 then
            local player = QBCore.Functions.GetPlayer(source)
            local firstnameinfo = player.PlayerData.charinfo.firstname
            local lastnameinfo = player.PlayerData.charinfo.lastname
            local csninfo = player.PlayerData.citizenid
            
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(vehicle) then
                local plate = GetVehicleNumberPlateText(vehicle)

                TriggerClientEvent('chat:addMessage', source, {
                    template = '<div class="chat-message advert"><div class="chat-message-body"><strong>{0}:</strong><br><br> <strong>First Name:</strong> {1} <br><strong>Last Name:</strong> {2} <br><strong>CSN:</strong> {3} <br><strong>Plate:</strong> {4} </div></div>',
                    args = {"Rental Papers", tostring(firstnameinfo), tostring(lastnameinfo), tostring(csninfo), tostring(plate)}
                })
            else
            end
        end
    end
end)
