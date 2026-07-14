fx_version 'cerulean'
game 'gta5'

author 'Ben'
description 'fivem-greenscreener'
version '1.7.0'

this_is_a_map 'yes'

ui_page 'html/index.html'

files {
    'html/*'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'screenshot-basic',
}
