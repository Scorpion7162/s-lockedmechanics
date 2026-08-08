-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

Restrictions = {}

-- GetVehicleType reports the network object type, which does not always agree
-- with the showroom class, so this errs towards allowing to avoid false denials.
---@type table<integer, table<string, true>>
local CLASS_TYPES = {}

do
    local automobile = { automobile = true }

    for _, class in ipairs({ 0, 1, 2, 3, 4, 5, 6, 7, 9, 12, 22 }) do
        CLASS_TYPES[class] = automobile
    end

    CLASS_TYPES[8]  = { bike = true, automobile = true }     -- trikes are automobiles
    CLASS_TYPES[13] = { bike = true }
    CLASS_TYPES[10] = { automobile = true, trailer = true }
    CLASS_TYPES[11] = { automobile = true, trailer = true }
    CLASS_TYPES[14] = { boat = true, submarine = true }
    CLASS_TYPES[15] = { heli = true }
    CLASS_TYPES[16] = { plane = true, heli = true }          -- blimps report as helis
    CLASS_TYPES[17] = { automobile = true, trailer = true }
    CLASS_TYPES[20] = { automobile = true, trailer = true }
    CLASS_TYPES[21] = { train = true }

    -- Emergency and military span every vehicle type.
    CLASS_TYPES[18] = { automobile = true, bike = true, heli = true, plane = true, boat = true }
    CLASS_TYPES[19] = { automobile = true, bike = true, heli = true, plane = true, boat = true, trailer = true }
end

---@param model integer
---@param vehicle integer
---@param reported any class claimed by the client
---@return integer? class nil when it cannot be trusted
function Restrictions.resolveClass(model, vehicle, reported)
    local pinned = ShopConfig.classOverrides[model]
    if pinned then return pinned end

    if type(reported) ~= 'number' then return nil end

    local class = math.floor(reported)
    if class < 0 or class > ShopConfig.MAX_CLASS then return nil end

    local expected = CLASS_TYPES[class]
    if not expected then return nil end

    local vehicleType = GetVehicleType(vehicle)
    if vehicleType and not expected[vehicleType] then return nil end

    return class
end

---@param shop table
---@param vehicle integer
---@param reportedClass any
---@return boolean allowed
---@return string? reason locale key, set when denied
function Restrictions.check(shop, vehicle, reportedClass)
    -- joaat() is unsigned but GetEntityModel can be signed, so both are squashed
    -- to the same form or hashes above 0x7FFFFFFF would never match.
    local model = ShopConfig.hash(GetEntityModel(vehicle))

    if shop.bannedModels[model] then return false, 'modelBanned' end
    if shop.allowedModels[model] then return true end

    -- Reads the flags rather than the sets, so a list of typos fails closed.
    if not shop.hasClassRules then return true end

    local class = Restrictions.resolveClass(model, vehicle, reportedClass)
    if not class then return false, 'invalidVehicle' end

    if shop.hasAllowedClasses and not shop.allowedClasses[class] then return false, 'classNotAllowed' end
    if shop.bannedClasses[class] then return false, 'classBanned' end

    return true
end

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
