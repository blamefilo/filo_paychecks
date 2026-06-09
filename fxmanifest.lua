fx_version "cerulean"
game "gta5"
lua54 "yes"

author "filo studios."
discord "https://discord.gg/EWKWXVBHK7"
repository "https://github.com/blamefilo/filo_paychecks"
description "Paychecks System"
version "1.0.0"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/sh-config.lua",
    "shared/sh-init.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/sv-*.lua"
}

client_scripts {
    "client/cl-*.lua"
}

files {
    "data/*",
}

dependencies {
    "community_bridge"
}