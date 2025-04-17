fx_version 'cerulean'
game 'gta5'

author 'PrimoAL'
description 'Easter Egg Hunt'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sfx/open.mp3'
}