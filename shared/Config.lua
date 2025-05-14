-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/

Config = {}
Config.Framework = 'auto' -- auto, qbx, qb, esx, standalone,
Config.UseClass = true -- true or false, if you want to use class system.
--                {⚠️⚠️ WARNING ⚠️⚠️}
-- NOTE: THIS CONFIG IS IGNORED IF USECLASS IS TRUE
Config.VehicleModelHash = {`model1`,`model2`} -- Follow the same format, it is a table.
-- NOTE: THIS CONFIG IS IGNORED IF USECLASS IS FALSE
Config.LockedClass = {'motorcycle'} -- Follow the same format, it is a table.
Config.Notify = 'ox_lib' -- ox_lib, qb, mythic, okok, custom.
Config.GroupLocked = false -- true or false, if you want to use the grouplock system.
Config.GroupName = 'ballas' -- The name of the group you want to lock the mechanic to. 
Config.MechID = 'bennys'  -- The ID of the mechanic job, this is used to check the mechanic name in the jg resource.
Config.MechLabel = 'Bennys' -- The label of the mechanic job, this is used to check the mechanic name in the jg resource.
Config.Location = vec3(-211.0, -1324.0, 30.9) -- The location of the mechanic thats locked
Config.Distance = 10.0 -- The distance to check if the player is near the mechanic.
Config.CooldownTime = 2000 -- cookldown time (MS)

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
