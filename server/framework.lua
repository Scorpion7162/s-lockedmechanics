-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

Framework = {}

local cached

local function isRunning(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

---@param configured string? 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone'
---@return string
function Framework.resolve(configured)
    if configured and configured ~= 'auto' then return configured end
    if cached then return cached end

    -- qbx_core first, as qbx_core provides qb-core in manifest so it will show as started.
    if isRunning('qbx_core') then
        cached = 'qbx'
    elseif isRunning('qb-core') then
        cached = 'qb'
    elseif isRunning('es_extended') then
        cached = 'esx'
    else
        cached = 'standalone'
    end

    return cached
end

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
