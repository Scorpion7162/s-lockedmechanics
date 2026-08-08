-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
return {
    -- 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone'
    framework = 'auto',

    -- Any shop can override any of these via its own `locale` table.
    locale = {
        noPermission    = "You don't have permission to use this mechanic",
        classNotAllowed = 'We don\'t work on that kind of vehicle here',
        classBanned     = 'We don\'t work on that kind of vehicle here',
        modelBanned     = 'We don\'t work on that model here',
        notInVehicle    = 'You need to be in a vehicle',
        tooFar          = 'You are too far from the mechanic',
        cooldown        = 'Please wait before trying again',
        invalidVehicle  = 'Invalid vehicle',
    },

    -- Pins a model's class server-side, ignoring what the client reports.
    -- [modelHash] = classId. See "Security notes" in the readme.
    classOverrides = {
        -- [`bati`] = 8,
        -- [`adder`] = 7,
    },

    shops = {
        bennys = {
            -- Must match a key in jg-mechanic Config.MechanicLocations.
            mechId = 'bennys',
            mechLabel = 'Bennys',

            -- Keep at or above interactDistance in config/cl.lua, to allow for lag.
            accessDistance = 5.0,
            cooldown = 2000,

            -- { ['jobOrGangName'] = minimumGrade }, empty means open to everyone.
            groups = {},

            -- Vehicle rules, all optional. See "Vehicle rules" in the readme for
            -- the order they are applied in.
            allowedClasses = {},
            bannedClasses  = { 'motorcycle', 'cycles' }, -- 'cycles' is class 13, pedal bikes
            allowedModels  = {},
            bannedModels   = {},

            -- Overrides the shared locale table above, per message.
            locale = {},
        },

        tuners = {
            mechId = 'tuners',
            mechLabel = 'Tuner Shop',
            accessDistance = 4.5,
            cooldown = 2000,

            -- Only mechanics of any grade, and Ballas of grade 2 or higher.
            groups = {
                mechanic = 0,
                ballas   = 2,
            },

            -- Sports and supercars only, but never the Adder.
            allowedClasses = { 'sports', 'sportsclassic', 'super' },
            bannedClasses  = {},
            allowedModels  = {},
            bannedModels   = { 'adder' },

            locale = {
                noPermission = 'This shop only serves its own crew',
            },
        },
    },
}

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
