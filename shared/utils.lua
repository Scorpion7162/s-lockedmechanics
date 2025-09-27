cachedFramework = nil

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
