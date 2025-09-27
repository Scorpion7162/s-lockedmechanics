local Config = lib.load('shared.Config')
local function SendNotification(message, type)
    local framework = Config.Framework
    if framework == 'auto' then
        framework = LoadFramework()
    end
    
    if framework == 'qb' then
        TriggerEvent('QBCore:Notify', message, type or 'error')
    elseif framework == 'qbx' then
        lib.notify({title = 'Notification', description = message, type = type or 'error', position = 'top-right', duration = 5000})
    elseif framework == 'esx' then
        TriggerEvent('esx:showNotification', message)
    else
        lib.notify({ title = 'Notification', description = message, type = type or 'error', position = 'top-right', duration = 5000 })
    end
end

local function RequestMechanicAccess()
    local success = lib.callback.await('s-lockmech:server:CheckAccess', false)
    if success then
        TriggerEvent("jg-mechanic:client:open-customisation-menu", Config.MechId, Config.MechLabel)
    end
end

local inZone = false

CreateThread(function()
    if not Config.Location then return end
    
    if Config.Interaction == 'ox_target' then
        exports.ox_target:addSphereZone({
            coords = Config.Location,
            radius = 2.0,
            options = {
                {
                    name = 's-lockedmechanic',
                    event = 's-lockmech:client:RequestAccess',
                    icon = 'fas fa-wrench',
                    label = 'Access Mechanic',
                }
            }
        })
    elseif Config.Interaction == 'qb-target' then
        exports['qb-target']:AddBoxZone("s-lockedmechanic", Config.Location, 2.0, 2.0, {
            name = "s-lockedmechanic",
            heading = 0,
            debugPoly = false,
            minZ = Config.Location.z - 1,
            maxZ = Config.Location.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "s-lockmech:client:RequestAccess",
                    icon = "fas fa-wrench",
                    label = "Access Mechanic",
                },
            },
            distance = 2.5,
        })
    elseif Config.Interaction == 'zones' then
        lib.zones.sphere({
            coords = Config.Location,
            radius = Config.Distance or 2.0,
            onEnter = function()
                inZone = true
                lib.showTextUI('[E] Access Mechanic', { position = 'left-center' })
            end,
            onExit = function()
                inZone = false
                lib.hideTextUI()
            end,
            debug = Config.Debug or false
        })
        
        CreateThread(function()
            while true do
                Wait(inZone and 0 or 500)
                if inZone and IsControlJustPressed(0, 38) then -- E key
                    RequestMechanicAccess()
                end
            end
        end)
    end
end)

RegisterNetEvent('s-lockmech:client:RequestAccess', function()
    RequestMechanicAccess()
end)

RegisterNetEvent('s-lockmech:client:Notify', function(message, type)
    SendNotification(message, type)
end)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
