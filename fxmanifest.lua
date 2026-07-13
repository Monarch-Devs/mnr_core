fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnr_core'
description 'Monarch Devs Framework'
author 'IlMelons'
version '1.0.0'
repository 'https://github.com/Monarch-Devs/mnr_core'

files {}

shared_scripts {
    '@ox_lib/init.lua',
    '@mnr_api/api.lua',
}

client_scripts {
    'client/**/*.lua',
}

server_scripts {
    '@mnr_sql/api.lua',
    'config/*.lua',
    'server/system.lua',
    'server/groups/*.lua',
    'server/groups.lua',
    'server/player/*.lua',
    'server/player.lua',
}