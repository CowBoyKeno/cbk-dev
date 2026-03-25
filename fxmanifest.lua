fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cbk-dev'
author 'CowBoyKeno'
description 'Standalone F1 development menu for private/dev servers'
version '3.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

shared_script 'shared/config.lua'
client_script 'client/main.lua'
