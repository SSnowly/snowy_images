fx_version  'cerulean'
game        'gta5'
lua54       'yes'

name        'Snowy Images'
description 'Oxinventory extension for proper image organization, while still making sure ox can use the right item images from us.'
author      'Snowylol'
version     '0.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
}
