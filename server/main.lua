-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

local playerCooldowns = {}
local Config = lib.load('shared.Config')


local classNames = {
    [0] = 'compacts', [1] = 'sedan', [2] = 'suv', [3] = 'coupe', 
    [4] = 'muscle', [5] = 'sports', [6] = 'sports classic', [7] = 'super', 
    [8] = 'motorcycle', [9] = 'offroad', [10] = 'industrial', [11] = 'utility', 
    [12] = 'van', [13] = 'bike', [14] = 'boat', [15] = 'helicopter', 
    [16] = 'plane', [17] = 'service', [18] = 'emergency', [19] = 'military', 
    [20] = 'commercial', [21] = 'train'
}

local classLookup = {}
local modelLookup = {}

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    for i, className in pairs(Config.LockedClass or {}) do
        classLookup[className] = true
    end
    
    for i, model in pairs(Config.VehicleModelHash or {}) do
        modelLookup[model] = true
    end
end)

local function CheckPermission(source)
    if not Config.GroupLocked then
        return true
    end
    
    local framework = Config.Framework
    if framework == 'auto' then
        framework = LoadFramework()
    end
    
    if framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return (Player.PlayerData.job.name == Config.GroupName or Player.PlayerData.gang.name == Config.GroupName)
        end
    elseif framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player then
            if exports.qbx_core:HasGroup(source, Config.GroupName) then
                return true
            end
        end
    elseif framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local Player = ESX.GetPlayerFromId(source)
        if Player then
            return (Player.job.name == Config.GroupName)
        end
    elseif framework == 'standalone' then
        return true
    end
    
    return false
end

local function SendNotification(src, message, type)
    local framework = Config.Framework
    if framework == 'auto' then
        framework = LoadFramework()
    end
    
    if framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, message, type or 'error')
    elseif framework == 'qbx' then
        TriggerClientEvent('s-lockmech:client:Notify', src, message, type or 'error')
    elseif framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        TriggerClientEvent('s-lockmech:client:Notify', src, message, type or 'error')
    end
end

local function CheckVehicleRestrictions(src, vehicleEntity)
    -- Validate entity exists
    if not DoesEntityExist(vehicleEntity) then
        SendNotification(src, 'Invalid vehicle')
        return false
    end
    
    local vehicleClass = GetVehicleClass(vehicleEntity)
    local vehicleModel = GetEntityModel(vehicleEntity)
    
    if Config.UseClass then
        local vehicleClassName = classNames[vehicleClass]
        
        -- If using whitelist approach (Config.LockedClass contains ALLOWED classes)
        if next(Config.LockedClass or {}) then
            if classLookup[vehicleClassName] then
                return true -- Vehicle IS allowed
            end
            SendNotification(src, 'This vehicle class is not allowed at this mechanic')
            return false
        else
            return true -- No restrictions if LockedClass is empty
        end
    else
        -- If using whitelist approach (Config.VehicleModelHash contains ALLOWED models)
        if next(Config.VehicleModelHash or {}) then
            if modelLookup[vehicleModel] then
                return true -- Vehicle IS allowed
            end
            SendNotification(src, 'This vehicle model is not allowed at this mechanic')
            return false
        else
            return true -- No restrictions if VehicleModelHash is empty
        end
    end
end

lib.callback.register('s-lockmech:server:CheckAccess', function(source)
    local src = source
    
    -- Rate limiting with stricter cooldown
    if playerCooldowns[src] and playerCooldowns[src] > GetGameTimer() then
        SendNotification(src, 'Please wait before trying again')
        return false
    end
    
    playerCooldowns[src] = GetGameTimer() + (Config.CooldownTime or 3000) -- Increased default cooldown
    
    if not CheckPermission(src) then
        SendNotification(src, 'You don\'t have permission to use this mechanic')
        return false
    end
    
    local playerPed = GetPlayerPed(src)
    if not DoesEntityExist(playerPed) then
        SendNotification(src, 'Invalid player entity')
        return false
    end
    
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    if playerVehicle == 0 then
        SendNotification(src, 'You need to be in a vehicle')
        return false
    end
    
    -- Server-side distance validation for extra security
    local playerCoords = GetEntityCoords(playerPed)
    if not playerCoords then
        SendNotification(src, 'Unable to get player position')
        return false
    end
    
    local distance = #(playerCoords - Config.Location)
    if distance > (Config.Distance or 5.0) then -- Server validates with potentially different distance
        SendNotification(src, 'You are too far from the mechanic')
        return false
    end
    
    if not CheckVehicleRestrictions(src, playerVehicle) then
        return false
    end
    
    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerCooldowns[src] = nil
end)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
