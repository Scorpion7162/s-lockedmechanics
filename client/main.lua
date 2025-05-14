-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

local cachedFramework = nil
local playerCooldowns = {}

function LoadFramework()
    if not cachedFramework then
        local qbState = GetResourceState('qb-core')
        local esxState = GetResourceState('es_extended')
        local qbxState = GetResourceState('qbx_core')
        
        if qbState == 'started' or qbState == 'starting' then
            cachedFramework = 'qb'
        elseif esxState == 'started' or esxState == 'starting' then
            cachedFramework = 'esx'
        elseif qbxState == 'started' or qbxState == 'starting' then
            cachedFramework = 'qbx'
        else
            cachedFramework = 'standalone'
        end
    end
    return cachedFramework
end

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
        lib.callback('s-lockmech:client:Notify', src, function() end, message, type or 'error')
    elseif framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        lib.callback('s-lockmech:client:Notify', src, function() end, message, type or 'error')
    end
end

local function CheckVehicleRestrictions(src, vehicleEntity)
    local vehicleClass = GetVehicleClass(vehicleEntity)
    local vehicleModel = GetEntityModel(vehicleEntity)
    
    if Config.UseClass then
        local vehicleClassName = classNames[vehicleClass]
        
        if classLookup[vehicleClassName] then
            return true
        end
        
        SendNotification(src, 'This vehicle class is not allowed at this mechanic')
        return false
    else
        if modelLookup[vehicleModel] then
            return true
        end
        
        SendNotification(src, 'This vehicle model is not allowed at this mechanic')
        return false
    end
end

lib.callback.register('s-lockmech:server:CheckAccess', function(source)
    local src = source
    
    if playerCooldowns[src] and playerCooldowns[src] > GetGameTimer() then
        SendNotification(src, 'Please wait before trying again')
        return false
    end
    
    playerCooldowns[src] = GetGameTimer() + (Config.CooldownTime or 2000)
    
    if not CheckPermission(src) then
        SendNotification(src, 'You don\'t have permission to use this mechanic')
        return false
    end
    
    local playerPed = GetPlayerPed(src)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    
    if playerVehicle == 0 then
        SendNotification(src, 'You need to be in a vehicle')
        return false
    end
    
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - Config.Location)
    
    if distance > Config.Distance then
        SendNotification(src, 'You are too far from the mechanic')
        return false
    end
    
    if not CheckVehicleRestrictions(src, playerVehicle) then
        return false
    end
    
    lib.callback('s-lockmech:client:OpenMenu', src, function() end)
    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    playerCooldowns[src] = nil
end)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
