fx_version 'cerulean'
game 'gta5'
author 'Scorpion'
description 'A simple resource to lock JG mechanic behind certain classes/vehicles, for more support join the discord'
discord 'discord.gg/jgscripts'
version '1.0.0'
-- Optimisation stuff
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
    'shared/*.lua',
}

-- dependencies
dependencies {
    'ox_lib',
    'jg-mechanic',
    '/server:7290',
    '/onesync',
}