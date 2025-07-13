local screens = {}
local isUIOpen = false
local currentScreen = nil
local playerPermission = "user"

-- تهيئة السكربت
Citizen.CreateThread(function()
    -- تحميل الشاشات الافتراضية
    for _, screen in pairs(Config.DefaultScreens) do
        screens[screen.id] = screen
    end
    
    -- طلب البيانات من السيرفر
    TriggerServerEvent('cinema:requestData')
end)

-- تحقق من صلاحيات اللاعب
function CheckPermission()
    -- هنا يمكن ربطه بنظام الصلاحيات الخاص بك
    local group = GetPlayerGroup() -- دالة وهمية - استبدلها بنظامك
    return Config.Permissions[group] or false
end

-- أمر فتح القائمة
RegisterCommand(Config.Command, function()
    if not CheckPermission() then
        ShowNotification(Config.Messages.no_permission)
        return
    end
    
    if isUIOpen then
        CloseUI()
    else
        OpenUI()
    end
end, false)

-- فتح واجهة التحكم
function OpenUI()
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "open",
        screens = screens,
        config = Config
    })
    ShowNotification(Config.Messages.cinema_opened)
end

-- إغلاق واجهة التحكم
function CloseUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "close"
    })
    ShowNotification(Config.Messages.cinema_closed)
end

-- معالجة رسائل NUI
RegisterNUICallback('close', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('addScreen', function(data, cb)
    local screenCount = 0
    for _ in pairs(screens) do
        screenCount = screenCount + 1
    end
    
    if screenCount >= Config.MaxScreens then
        ShowNotification(Config.Messages.max_screens)
        cb('error')
        return
    end
    
    local newId = GetNextScreenId()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    local newScreen = {
        id = newId,
        name = data.name or "شاشة جديدة",
        coords = playerCoords,
        rotation = vector3(0.0, 0.0, 0.0),
        scale = vector3(5.0, 3.0, 1.0),
        url = "",
        volume = Config.DefaultVolume,
        active = false
    }
    
    screens[newId] = newScreen
    TriggerServerEvent('cinema:updateScreen', newScreen)
    ShowNotification(Config.Messages.screen_added)
    cb('ok')
end)

RegisterNUICallback('updateScreen', function(data, cb)
    if screens[data.id] then
        screens[data.id] = data
        TriggerServerEvent('cinema:updateScreen', data)
        ShowNotification(Config.Messages.screen_updated)
    end
    cb('ok')
end)

RegisterNUICallback('deleteScreen', function(data, cb)
    if screens[data.id] then
        screens[data.id] = nil
        TriggerServerEvent('cinema:deleteScreen', data.id)
        ShowNotification(Config.Messages.screen_removed)
    end
    cb('ok')
end)

RegisterNUICallback('playVideo', function(data, cb)
    if screens[data.id] then
        screens[data.id].url = data.url
        screens[data.id].active = true
        TriggerServerEvent('cinema:playVideo', data.id, data.url)
    end
    cb('ok')
end)

RegisterNUICallback('stopVideo', function(data, cb)
    if screens[data.id] then
        screens[data.id].active = false
        TriggerServerEvent('cinema:stopVideo', data.id)
    end
    cb('ok')
end)

RegisterNUICallback('setVolume', function(data, cb)
    if screens[data.id] then
        screens[data.id].volume = data.volume
        TriggerServerEvent('cinema:setVolume', data.id, data.volume)
    end
    cb('ok')
end)

RegisterNUICallback('teleportToScreen', function(data, cb)
    if screens[data.id] then
        local coords = screens[data.id].coords
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
    end
    cb('ok')
end)

-- أحداث السيرفر
RegisterNetEvent('cinema:syncScreens')
AddEventHandler('cinema:syncScreens', function(serverScreens)
    screens = serverScreens
    if isUIOpen then
        SendNUIMessage({
            type = "updateScreens",
            screens = screens
        })
    end
end)

RegisterNetEvent('cinema:syncVideo')
AddEventHandler('cinema:syncVideo', function(screenId, url)
    if screens[screenId] then
        screens[screenId].url = url
        screens[screenId].active = true
    end
end)

RegisterNetEvent('cinema:syncStop')
AddEventHandler('cinema:syncStop', function(screenId)
    if screens[screenId] then
        screens[screenId].active = false
    end
end)

RegisterNetEvent('cinema:syncVolume')
AddEventHandler('cinema:syncVolume', function(screenId, volume)
    if screens[screenId] then
        screens[screenId].volume = volume
    end
end)

-- رسم الشاشات
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        for _, screen in pairs(screens) do
            if screen.active then
                DrawScreen(screen)
            end
        end
    end
end)

-- رسم الشاشة
function DrawScreen(screen)
    local coords = screen.coords
    local scale = screen.scale
    
    -- رسم مربع الشاشة
    DrawBox(coords.x, coords.y, coords.z, scale.x, scale.y, scale.z, 0, 0, 0, 200)
    
    -- رسم النص
    if screen.url and screen.url ~= "" then
        Draw3DText(coords.x, coords.y, coords.z + 1.0, screen.name, 0.4)
        Draw3DText(coords.x, coords.y, coords.z + 0.7, "الصوت: " .. math.floor(screen.volume * 100) .. "%", 0.3)
    end
end

-- دوال مساعدة
function GetNextScreenId()
    local maxId = 0
    for id, _ in pairs(screens) do
        if id > maxId then
            maxId = id
        end
    end
    return maxId + 1
end

function ShowNotification(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

function DrawBox(x, y, z, width, height, length, r, g, b, a)
    DrawBox(x - width/2, y - height/2, z - length/2, x + width/2, y + height/2, z + length/2, r, g, b, a)
end

function Draw3DText(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * scale
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- دالة وهمية للحصول على مجموعة اللاعب
function GetPlayerGroup()
    -- استبدل هذه الدالة بنظام الصلاحيات الخاص بك
    return "admin" -- مثال
end