-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

return {
    -- Draws the interaction zones so you can see them in game.
    debug = false,

    -- How rejection messages are shown: 'ox_lib' | 'qb' | 'esx' | 'mythic' | 'okok'
    notify = 'ox_lib',

    -- Shop keys must match config/sv.lua. Keys are not secret, mechId is.
    shops = {
        bennys = {
            interaction = 'zones', -- 'zones' | 'ox_target' | 'qb-target'
            label = 'Access Mechanic',

            -- Keep at or below accessDistance in config/sv.lua.
            interactDistance = 3.0,

            locations = {
                vec3(-211.0, -1324.0, 30.9),
            },
        },

        tuners = {
            interaction = 'ox_target',
            label = 'Access Tuning Shop',
            interactDistance = 2.5,
            locations = {
                vec3(-337.18, -136.29, 39.01),
                vec3(731.68, -1088.83, 22.17),
            },
        },
    },
}

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
