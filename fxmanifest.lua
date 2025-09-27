-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
fx_version 'cerulean'
game 'gta5'
author 'Scorpion'
description 'A simple resource to lock JG mechanic behind certain classes/vehicles - This is not an official JG resource, please open an issue on GitHub if you have any problems.'
version '1.2.0'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

-- Defining what is in the resource
client_scripts {
    'client/*.lua',
}
server_scripts {
    'server/*.lua',
}
shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

-- dependencies
dependencies {
    'ox_lib',
    'jg-mechanic',
    '/server:7290',
    '/onesync',
}

-- This resource is protected under the GNU General Public License v3.0.
-- You may not redistribute this code without providing clear attribution to the original author.
-- https://choosealicense.com/licenses/gpl-3.0/
