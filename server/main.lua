-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

local cooldowns = {}

-- Applies even to unknown shop keys, so junk requests cannot spam the callback.
local MIN_COOLDOWN = 250

---@param src integer
---@param shop table
---@param messageKey string
local function deny(src, shop, messageKey)
    TriggerClientEvent('s-lockmech:client:notify', src, ShopConfig.message(shop, messageKey))
end

---@param coords vector3
---@param locations vector3[]
---@param maxDistance number
---@return boolean
local function isNearAnyLocation(coords, locations, maxDistance)
    for _, location in ipairs(locations) do
        if #(coords - location) <= maxDistance then return true end
    end

    return false
end

---@param source integer
---@param shopKey any
---@param reportedClass any
---@return boolean
lib.callback.register('s-lockmech:server:requestAccess', function(source, shopKey, reportedClass)
    local src = source
    local now = GetGameTimer()
    local readyAt = cooldowns[src]

    -- Silent on unknown keys, so notifications cannot be used to probe for them.
    local shop = ShopConfig.get(shopKey)

    if not shop then
        cooldowns[src] = now + MIN_COOLDOWN
        return false
    end

    if readyAt and readyAt > now then
        deny(src, shop, 'cooldown')
        return false
    end

    cooldowns[src] = now + math.max(shop.cooldown, MIN_COOLDOWN)

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        deny(src, shop, 'notInVehicle')
        return false
    end

    if not isNearAnyLocation(GetEntityCoords(ped), shop.locations, shop.accessDistance) then
        deny(src, shop, 'tooFar')
        return false
    end

    if not Permissions.check(src, shop) then
        deny(src, shop, 'noPermission')
        return false
    end

    local allowed, reason = Restrictions.check(shop, vehicle, reportedClass)
    if not allowed then
        deny(src, shop, reason)
        return false
    end

    -- Opened from the server, so the client never has to hold or forward the id.
    TriggerClientEvent('jg-mechanic:client:open-customisation-menu', src, shop.mechId, shop.mechLabel)

    return true
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
