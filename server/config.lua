-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

ShopConfig = {}

local RESOURCE = GetCurrentResourceName()

-- 5 is Sports Classics and 6 is Sports, which is the opposite of what v1 had.
---@type table<string, integer>
local CLASS_IDS = {
    ['compacts']        = 0,
    ['compact']         = 0,
    ['sedans']          = 1,
    ['sedan']           = 1,
    ['suvs']            = 2,
    ['suv']             = 2,
    ['coupes']          = 3,
    ['coupe']           = 3,
    ['muscle']          = 4,
    ['sports classics'] = 5,
    ['sports classic']  = 5,
    ['sportsclassic']   = 5,
    ['sports']          = 6,
    ['sport']           = 6,
    ['super']           = 7,
    ['motorcycles']     = 8,
    ['motorcycle']      = 8,
    ['offroad']         = 9,
    ['off-road']        = 9,
    ['industrial']      = 10,
    ['utility']         = 11,
    ['vans']            = 12,
    ['van']             = 12,
    ['cycles']          = 13,
    ['cycle']           = 13,
    ['bicycle']         = 13,
    -- No 'bike' alias on purpose, it reads as motorcycles but means class 13.
    ['boats']           = 14,
    ['boat']            = 14,
    ['helicopters']     = 15,
    ['helicopter']      = 15,
    ['heli']            = 15,
    ['planes']          = 16,
    ['plane']           = 16,
    ['service']         = 17,
    ['emergency']       = 18,
    ['military']        = 19,
    ['commercial']      = 20,
    ['trains']          = 21,
    ['train']           = 21,
    ['open wheel']      = 22,
    ['openwheel']       = 22,
}

ShopConfig.CLASS_IDS = CLASS_IDS
ShopConfig.MAX_CLASS = 22

local VALID_INTERACTIONS = {
    ['zones'] = true,
    ['ox_target'] = true,
    ['qb-target'] = true,
}

local VALID_FRAMEWORKS = {
    ['auto'] = true,
    ['qbx'] = true,
    ['qb'] = true,
    ['esx'] = true,
    ['standalone'] = true,
}

-- Squashes signed and unsigned forms together so hash comparisons match.
---@param value number
---@return integer
function ShopConfig.hash(value)
    return math.floor(value) & 0xFFFFFFFF
end

local shops = {}
local warnings = 0

local function warn(message, ...)
    warnings = warnings + 1
    print(('^3[%s]^7 warning: %s'):format(RESOURCE, message:format(...)))
end

---@param value any
---@return boolean
local function isNonEmptyTable(value)
    return type(value) == 'table' and next(value) ~= nil
end

---Turn a config list of class names/ids into a set keyed by class id.
---@param list any
---@param shopKey string
---@param field string
---@return table<integer, true>
local function toClassSet(list, shopKey, field)
    local set = {}
    if list == nil then return set end

    if type(list) ~= 'table' then
        warn("shop '%s' field '%s' must be a table, got %s", shopKey, field, type(list))
        return set
    end

    for _, entry in pairs(list) do
        local id

        if type(entry) == 'number' then
            id = math.floor(entry)
            if id < 0 or id > ShopConfig.MAX_CLASS then
                warn("shop '%s' field '%s' has class id %d, expected 0-%d", shopKey, field, id, ShopConfig.MAX_CLASS)
                id = nil
            end
        elseif type(entry) == 'string' then
            id = CLASS_IDS[entry:lower()]
            if not id then
                warn("shop '%s' field '%s' has unknown class name '%s'", shopKey, field, entry)
            end
        else
            warn("shop '%s' field '%s' has a %s entry, expected a class name or id", shopKey, field, type(entry))
        end

        if id then set[id] = true end
    end

    return set
end

---Turn a config list of model names/hashes into a set keyed by model hash.
---@param list any
---@param shopKey string
---@param field string
---@return table<integer, true>
local function toModelSet(list, shopKey, field)
    local set = {}
    if list == nil then return set end

    if type(list) ~= 'table' then
        warn("shop '%s' field '%s' must be a table, got %s", shopKey, field, type(list))
        return set
    end

    for _, entry in pairs(list) do
        if type(entry) == 'string' then
            set[ShopConfig.hash(joaat(entry))] = true
        elseif type(entry) == 'number' then
            set[ShopConfig.hash(entry)] = true
        else
            warn("shop '%s' field '%s' has a %s entry, expected a model name or hash", shopKey, field, type(entry))
        end
    end

    return set
end

---@param groups any
---@param shopKey string
---@return table<string, integer>
local function toGroupSet(groups, shopKey)
    local set = {}
    if groups == nil then return set end

    if type(groups) ~= 'table' then
        warn("shop '%s' field 'groups' must be a table, got %s", shopKey, type(groups))
        return set
    end

    for name, grade in pairs(groups) do
        if type(name) ~= 'string' then
            warn("shop '%s' has a group keyed by %s, expected { ['jobname'] = minGrade }", shopKey, type(name))
        elseif type(grade) ~= 'number' then
            warn("shop '%s' group '%s' has a %s grade, expected a number", shopKey, name, type(grade))
        else
            set[name] = math.floor(grade)
        end
    end

    return set
end

---@param locations any
---@param shopKey string
---@return vector3[]
local function toLocations(locations, shopKey)
    local list = {}

    if type(locations) ~= 'table' then
        warn("shop '%s' has no 'locations' table, it will be unreachable", shopKey)
        return list
    end

    for _, coords in pairs(locations) do
        if type(coords) == 'vector3' then
            list[#list + 1] = coords
        else
            warn("shop '%s' has a %s location, expected vec3(x, y, z)", shopKey, type(coords))
        end
    end

    if #list == 0 then
        warn("shop '%s' has an empty 'locations' table, it will be unreachable", shopKey)
    end

    return list
end

local function build()
    local cl = lib.load('config.cl')
    local sv = lib.load('config.sv')

    if type(cl) ~= 'table' or type(sv) ~= 'table' then
        print(('^1[%s]^7 failed to load config/cl.lua or config/sv.lua'):format(RESOURCE))
        return
    end

    -- An unknown value would deny every player at every group-locked shop.
    ShopConfig.framework = sv.framework or 'auto'
    if not VALID_FRAMEWORKS[ShopConfig.framework] then
        warn("framework '%s' is not one of auto/qbx/qb/esx/standalone, falling back to 'auto'",
            tostring(ShopConfig.framework))
        ShopConfig.framework = 'auto'
    end

    ShopConfig.notify = cl.notify or 'ox_lib'
    ShopConfig.locale = sv.locale or {}
    ShopConfig.classOverrides = {}

    for model, class in pairs(sv.classOverrides or {}) do
        if type(model) ~= 'number' or type(class) ~= 'number' then
            warn('classOverrides must map a model hash to a class id')
        else
            local id = math.floor(class)

            -- Overrides skip the normal validation, so a typo must be caught here.
            if id < 0 or id > ShopConfig.MAX_CLASS then
                warn('classOverrides entry for model %s has class id %d, expected 0-%d',
                    tostring(model), id, ShopConfig.MAX_CLASS)
            else
                ShopConfig.classOverrides[ShopConfig.hash(model)] = id
            end
        end
    end

    local clShops = cl.shops or {}
    local svShops = sv.shops or {}

    for key, svShop in pairs(svShops) do
        if not clShops[key] then
            warn("shop '%s' is in config/sv.lua but not config/cl.lua, so nothing will create its zone", key)
        end
    end

    for key, clShop in pairs(clShops) do
        local svShop = svShops[key]

        if not svShop then
            warn("shop '%s' is in config/cl.lua but not config/sv.lua, so it has no mechanic to open", key)
            goto continue
        end

        if type(svShop.mechId) ~= 'string' or svShop.mechId == '' then
            warn("shop '%s' has no 'mechId'. It must match a key in jg-mechanic Config.MechanicLocations", key)
        end

        local interaction = clShop.interaction or 'zones'
        if not VALID_INTERACTIONS[interaction] then
            warn("shop '%s' has unknown interaction '%s', falling back to 'zones'", key, tostring(interaction))
            interaction = 'zones'
        end

        local interactDistance = tonumber(clShop.interactDistance) or 3.0
        local accessDistance = tonumber(svShop.accessDistance) or (interactDistance + 2.0)

        if accessDistance < interactDistance then
            warn("shop '%s' has accessDistance (%.1f) below interactDistance (%.1f); players will see a prompt the server rejects",
                key, accessDistance, interactDistance)
        end

        -- Taken from the raw config so a list of typos still counts as a rule.
        local wroteAllowedClasses = isNonEmptyTable(svShop.allowedClasses)
        local wroteBannedClasses = isNonEmptyTable(svShop.bannedClasses)

        shops[key] = {
            key            = key,
            mechId         = svShop.mechId,
            mechLabel      = svShop.mechLabel or key,
            locations      = toLocations(clShop.locations, key),
            accessDistance = accessDistance,
            cooldown       = tonumber(svShop.cooldown) or 2000,
            groups         = toGroupSet(svShop.groups, key),
            allowedClasses = toClassSet(svShop.allowedClasses, key, 'allowedClasses'),
            bannedClasses  = toClassSet(svShop.bannedClasses, key, 'bannedClasses'),
            hasAllowedClasses = wroteAllowedClasses,
            hasClassRules  = wroteAllowedClasses or wroteBannedClasses,
            allowedModels  = toModelSet(svShop.allowedModels, key, 'allowedModels'),
            bannedModels   = toModelSet(svShop.bannedModels, key, 'bannedModels'),
            locale         = type(svShop.locale) == 'table' and svShop.locale or {},
        }

        ::continue::
    end

    local count = 0
    for _ in pairs(shops) do count = count + 1 end

    if warnings == 0 then
        print(('^2[%s]^7 loaded %d mechanic shop(s)'):format(RESOURCE, count))
    else
        print(('^3[%s]^7 loaded %d mechanic shop(s) with %d config warning(s)'):format(RESOURCE, count, warnings))
    end
end

---@param key any
---@return table?
function ShopConfig.get(key)
    if type(key) ~= 'string' then return nil end
    return shops[key]
end

---@param shop table
---@param messageKey string
---@return string
function ShopConfig.message(shop, messageKey)
    return shop.locale[messageKey] or ShopConfig.locale[messageKey] or messageKey
end

build()

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
