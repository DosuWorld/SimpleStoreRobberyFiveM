fx_version 'adamant'

game 'gta5'

description 'Basic Robbery Test Script'

version '1.0'

ui_page 'h.html'

shared_script {
 	'@es_extended/imports.lua',
    'config.lua' -- Add the configuration file directly
}


files {
    'h.html'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

client_scripts {
	'client/main.lua'
}
