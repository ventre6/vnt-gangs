fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'ventre'

shared_scripts {
    'config.lua'
}

client_script 'client/main.lua'

server_script 'server/main.lua'

server_script '@oxmysql/lib/MySQL.lua'
