fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'joinqueue'
description 'Connection queue with live queue card, priority tiers, Discord roles and crash grace'
version '1.1.0'
author 'IamZach'
discord 'https://discord.gg/agn'
repository 'https://github.com/1amZach/joinqueue'

server_scripts {
    'config.lua',
    'server/identity.lua',
    'server/priority.lua',
    'server/card.lua',
    'server/queue.lua',
    'server/commands.lua',
    'server/main.lua',
}
