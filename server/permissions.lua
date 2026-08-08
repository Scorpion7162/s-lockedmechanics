-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

Permissions = {}

-- Keeps the highest grade, so a gang cannot demote a job of the same name.
---@param groups table<string, integer>
---@param name any
---@param grade any
local function addGroup(groups, name, grade)
    if type(name) ~= 'string' or name == '' then return end

    local level = tonumber(grade) or 0

    if groups[name] == nil or level > groups[name] then
        groups[name] = level
    end
end

-- Uses each framework's own accessor, as helper export signatures vary by version.
---@param src integer
---@param framework string
---@return table<string, integer>?
local function getPlayerGroups(src, framework)
    if framework == 'qbx' or framework == 'qb' then
        local player

        if framework == 'qbx' then
            player = exports.qbx_core:GetPlayer(src)
        else
            player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        end

        if not player then return nil end

        local data = player.PlayerData
        local groups = {}

        if data.job then addGroup(groups, data.job.name, data.job.grade and data.job.grade.level) end
        if data.gang then addGroup(groups, data.gang.name, data.gang.grade and data.gang.grade.level) end

        return groups
    end

    if framework == 'esx' then
        local esx = exports['es_extended']:getSharedObject()
        local player = esx.GetPlayerFromId(src)
        if not player then return nil end

        local groups = {}
        if player.job then addGroup(groups, player.job.name, player.job.grade) end

        return groups
    end

    return nil
end

---@param src integer
---@param shop table
---@return boolean
function Permissions.check(src, shop)
    if not next(shop.groups) then return true end

    local framework = Framework.resolve(ShopConfig.framework)
    if framework == 'standalone' then return true end

    local groups = getPlayerGroups(src, framework)
    if not groups then return false end

    for name, grade in pairs(groups) do
        local required = shop.groups[name]
        if required and grade >= required then return true end
    end

    return false
end

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
