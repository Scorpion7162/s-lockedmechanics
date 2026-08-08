-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

local Config = lib.load('config.cl')
local shops = Config and Config.shops or {}

local RESOURCE = GetCurrentResourceName()

-- Live in another resource, so they need removing by hand on stop.
local oxTargetZones = {}
local qbTargetZones = {}

local activeShop
local textUiShown = false

---@param message string
local function notify(message)
    local style = Config.notify

    if style == 'qb' then
        TriggerEvent('QBCore:Notify', message, 'error')
    elseif style == 'esx' then
        TriggerEvent('esx:showNotification', message)
    elseif style == 'mythic' then
        TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = message })
    elseif style == 'okok' then
        TriggerEvent('okokNotify:Alert', 'Mechanic', message, 5000, 'error')
    else
        lib.notify({
            title = 'Mechanic',
            description = message,
            type = 'error',
            position = 'top-right',
            duration = 5000,
        })
    end
end

-- The server opens the menu itself on success, so nothing is done with the result.
---@param shopKey string
local function requestAccess(shopKey)
    local vehicle = cache.vehicle

    lib.callback.await('s-lockmech:server:requestAccess', false, shopKey,
        vehicle and GetVehicleClass(vehicle) or nil)
end

---@param shopKey string
---@param shop table
---@param coords vector3
---@param index integer
local function createOxTarget(shopKey, shop, coords, index)
    oxTargetZones[#oxTargetZones + 1] = exports.ox_target:addSphereZone({
        coords = coords,
        radius = shop.interactDistance or 2.0,
        debug = Config.debug,
        options = {
            {
                name = ('%s:%s:%d'):format(RESOURCE, shopKey, index),
                icon = 'fas fa-wrench',
                label = shop.label or 'Access Mechanic',
                onSelect = function()
                    requestAccess(shopKey)
                end,
            },
        },
    })
end

---@param shopKey string
---@param shop table
---@param coords vector3
---@param index integer
local function createQbTarget(shopKey, shop, coords, index)
    local name = ('%s:%s:%d'):format(RESOURCE, shopKey, index)
    qbTargetZones[#qbTargetZones + 1] = name

    exports['qb-target']:AddCircleZone(name, coords, shop.interactDistance or 2.0, {
        name = name,
        useZ = true,
        debugPoly = Config.debug,
    }, {
        options = {
            {
                type = 'client',
                icon = 'fas fa-wrench',
                label = shop.label or 'Access Mechanic',
                action = function()
                    requestAccess(shopKey)
                end,
            },
        },
        distance = (shop.interactDistance or 2.0) + 0.5,
    })
end

-- Occupancy is tracked per zone, so leaving one of two overlapping zones hands
-- the prompt back to the other rather than clearing it.
local occupied = {}
local nextZoneId = 0

local function refreshPrompt()
    local entry

    for _, value in pairs(occupied) do
        entry = value
        break
    end

    activeShop = entry and entry.shopKey

    if entry then
        textUiShown = true
        lib.showTextUI(('[E] %s'):format(entry.label), { position = 'left-center' })
    elseif textUiShown then
        textUiShown = false
        lib.hideTextUI()
    end
end

---@param shopKey string
---@param shop table
---@param coords vector3
local function createZone(shopKey, shop, coords)
    nextZoneId = nextZoneId + 1

    local zoneId = nextZoneId
    local label = shop.label or 'Access Mechanic'

    lib.zones.sphere({
        coords = coords,
        radius = shop.interactDistance or 3.0,
        debug = Config.debug,
        onEnter = function()
            occupied[zoneId] = { shopKey = shopKey, label = label }
            refreshPrompt()

            -- Polling runs only while inside, so no keypress is lost to an idle tick.
            CreateThread(function()
                while occupied[zoneId] do
                    Wait(0)

                    if activeShop == shopKey and IsControlJustPressed(0, 38) then
                        requestAccess(shopKey)
                    end
                end
            end)
        end,
        onExit = function()
            occupied[zoneId] = nil
            refreshPrompt()
        end,
    })
end

CreateThread(function()
    for shopKey, shop in pairs(shops) do
        local interaction = shop.interaction or 'zones'

        for index, coords in ipairs(shop.locations or {}) do
            if interaction == 'ox_target' then
                createOxTarget(shopKey, shop, coords, index)
            elseif interaction == 'qb-target' then
                createQbTarget(shopKey, shop, coords, index)
            else
                createZone(shopKey, shop, coords)
            end
        end
    end
end)

RegisterNetEvent('s-lockmech:client:notify', function(message)
    if type(message) ~= 'string' then return end
    notify(message)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end

    if textUiShown then lib.hideTextUI() end

    for _, id in ipairs(oxTargetZones) do
        exports.ox_target:removeZone(id)
    end

    for _, name in ipairs(qbTargetZones) do
        exports['qb-target']:RemoveZone(name)
    end
end)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
