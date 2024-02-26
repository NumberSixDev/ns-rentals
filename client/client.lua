local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ns-rentals:spawnvehicle', function(data)
    local ped = PlayerPedId()
    local coords = QBCore.Functions.GetCoords(ped)
    local vehicleIndex = data.vehicleIndex
    local vehicleName = Config.Rentals[vehicleIndex]
    local parkingCoords
    local prisonRentals = {
        vector3(1854.53, 2578.78, 45.67),
        vector3(1854.62, 2575.0, 45.67),
        vector3(1854.67, 2571.35, 45.67),
    }
    local legionRentals = {
        vector3(143.48, -1081.89, 29.19),
        vector3(139.82, -1081.83, 29.19),
        vector3(135.96, -1081.89, 29.19),
    }
    local hospitalRentals = {
        vector3(296.26, -611.01, 43.26),
        vector3(297.52, -608.34, 43.27),
        vector3(298.7, -605.42, 43.25),
    }

    if IsPlayerNearPrison(coords) then
        parkingCoords = GetRandomCoords(prisonRentals)
        parkingHeading = Config.Headings.PrisonHeading
    elseif IsPlayerNearLegion(coords) then
        parkingCoords = GetRandomCoords(legionRentals)
        parkingHeading = Config.Headings.LegionHeading
    elseif IsPlayerNearHospital(coords) then
        parkingCoords = GetRandomCoords(hospitalRentals)
        parkingHeading = Config.Headings.HospitalHeading
    else
    end
    
    QBCore.Functions.SpawnVehicle(vehicleName, function(vehicle)
        local plate = QBCore.Functions.GetPlate(vehicle)
        if plate then
            SetEntityCoords(vehicle, parkingCoords.x, parkingCoords.y, parkingCoords.z)
            SetEntityHeading(vehicle, parkingHeading)
            exports['LegacyFuel']:SetFuel(vehicle, Config.FuelSpawn)
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
            TriggerServerEvent("ns-rentals:server:PayForRental", plate)
        else
            print("Failed to retrieve vehicle plate")
        end
    end, parkingCoords, true, true)
end)

RegisterNetEvent('ns-rentals:returnvehicle', function(data)
    local src = source
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    QBCore.Functions.DeleteVehicle(vehicle)
    TriggerServerEvent("ns-rentals:server:removepapers")
    QBCore.Functions.Notify("You have received half of your initial payment back from the rental company!", "success", 5000)
end)

function IsPlayerNearPrison(coords)
    local prisonCoords = vector3(1852.74, 2582.61, 45.67)
    local prisonRentals = {
        vector3(1854.53, 2578.78, 45.67),
        vector3(1854.62, 2575.0, 45.67),
        vector3(1854.67, 2571.35, 45.67),
    }
    local pos = GetEntityCoords(PlayerPedId())
    for _, coord in ipairs(prisonRentals) do
        local dist = #(pos - coord)
        if dist < 30 then
            return true
        end
    end
    return false
end

function IsPlayerNearLegion(coords)
    local legionCoords = vector3(100.68, -1071.67, 29.24)
    local legionRentals = {
        vector3(143.48, -1081.89, 29.19),
        vector3(139.82, -1081.83, 29.19),
        vector3(135.96, -1081.89, 29.19),
    }
    local pos = GetEntityCoords(PlayerPedId())
    for _, coord in ipairs(legionRentals) do
        local dist = #(pos - coord)
        if dist < 30 then
            return true
        end
    end
    return false
end

function IsPlayerNearHospital(coords)
    local hospitalCoords = vector3(293.22, -612.47, 43.41)
    local hospitalRentals = {
        vector3(296.26, -611.01, 43.26),
        vector3(297.52, -608.34, 43.27),
        vector3(298.7, -605.42, 43.25),
    }
    local pos = GetEntityCoords(PlayerPedId())
    for _, coord in ipairs(hospitalRentals) do
        local dist = #(pos - coord)
        if dist < 30 then
            return true
        end
    end
    return false
end

function GetRandomCoords(coordsTable)
    local randomIndex = math.random(#coordsTable)
    return coordsTable[randomIndex]
end

RegisterNetEvent('ns-rentals:openmenu', function()
    local Player = QBCore.Functions.GetPlayerData()
    local jobName = Player.job.name
    local menuOptions = {
        {
            header = "Rental Vehicles",
            txt = ""
        }
    }

    if Config.JobLock and jobName ~= Config.JobLock then
        return
    end

    for i, rental in ipairs(Config.Rentals) do
        table.insert(menuOptions, {
            header = rental,
            txt = "Cost: £1,000",
            params = {
                type = "client",
                event = "ns-rentals:spawnvehicle",
                args = { vehicleIndex = i }
            }
        })
    end

    exports['menu']:openMenu(menuOptions)
end)

local locations = {
    { coords = vector3(1852.73, 2582.43, 45.67), actionEvent = "ns-rentals:openmenu", actionText = "[~g~E~w~] Rentals Menu", maxDistance = 1.0 },
    { coords = vector3(294.15, -612.61, 43.41), actionEvent = "ns-rentals:openmenu", actionText = "[~g~E~w~] Rentals Menu", maxDistance = 1.0 },
    { coords = vector3(141.67, -1085.33, 29.19), actionEvent = "ns-rentals:openmenu", actionText = "[~g~E~w~] Rentals Menu", maxDistance = 1.0 },
}

for _, location in ipairs(locations) do
    CreateThread(function()
        local sleep = 0
        while true do
            sleep = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local dist = #(pos - location.coords)
            if dist < location.maxDistance then
                sleep = 0
                if dist < location.maxDistance then
                    QBCore.Functions.DrawText3D(location.coords.x, location.coords.y, location.coords.z, location.actionText)
                    if IsControlJustReleased(0, 51) then
                        TriggerEvent(location.actionEvent)
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

local returnlocations = {
    { coords = vector3(1852.73, 2582.43, 45.67), actionEvent = "ns-rentals:returnvehicle", actionText = "[~g~E~w~] Return Rental Vehicle", maxDistance = 5.0 },
    { coords = vector3(294.15, -612.61, 43.41), actionEvent = "ns-rentals:returnvehicle", actionText = "[~g~E~w~] Return Rental Vehicle", maxDistance = 5.0 },
    { coords = vector3(141.67, -1085.33, 29.19), actionEvent = "ns-rentals:returnvehicle", actionText = "[~g~E~w~] Return Rental Vehicle", maxDistance = 5.0 },
}

for _, returnlocation in ipairs(returnlocations) do
    CreateThread(function()
        local sleep = 0
        while true do
            sleep = 1000
            local pos = GetEntityCoords(PlayerPedId())
            local ped = PlayerPedId()
            local dist = #(pos - returnlocation.coords)
            if dist < returnlocation.maxDistance then
                sleep = 0
                if dist < returnlocation.maxDistance and IsPedInAnyVehicle(ped, true) then
                    QBCore.Functions.DrawText3D(returnlocation.coords.x, returnlocation.coords.y, returnlocation.coords.z, returnlocation.actionText)
                    if IsControlJustReleased(0, 51) then
                        TriggerEvent(returnlocation.actionEvent)
                    end
                end
            end
            Wait(sleep)
        end
    end)
end
