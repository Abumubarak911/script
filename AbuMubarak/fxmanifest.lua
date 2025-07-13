fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Cinema Script - نظام سينما متطور لـ FiveM'
version '1.0.0'

-- Client Scripts
client_scripts {
    'config.lua',
    'client.lua'
}

-- Server Scripts
server_scripts {
    'config.lua',
    'server.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html'
}

-- Dependencies (اختياري)
dependencies {
    'mysql-async' -- إذا كنت تستخدم قاعدة بيانات MySQL
}

-- Exports (اختياري)
exports {
    'GetScreens',
    'GetScreenById',
    'IsScreenActive'
}

-- Server Exports (اختياري)
server_exports {
    'AddScreen',
    'RemoveScreen',
    'UpdateScreen'
}