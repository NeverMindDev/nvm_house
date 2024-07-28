fx_version 'bodacious'
games { 'gta5' }

author 'NeverMind'
description 'NVM HOUSING SYSTEM'
version '1.0.0'

client_scripts {
    'main/client.lua',
}

server_scripts {
    'main/server.lua',
    '@mysql-async/lib/MySQL.lua',
}

shared_script 'config.lua'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/script.js',
    'nui/style.css',    
    'config.lua',
}