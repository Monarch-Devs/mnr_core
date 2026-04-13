fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnr_core'
description 'Monarch Devs Framework'
author 'IlMelons'
version '0.0.1'
repository 'https://github.com/Monarch-Devs/mnr_core'

files {}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/system.lua',
    'server/groups/*.lua',
    'server/groups.lua',
    'server/player/*.lua',
    'server/player.lua',
}