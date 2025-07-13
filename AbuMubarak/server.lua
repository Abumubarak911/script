local screens = {}

-- تهيئة السيرفر
Citizen.CreateThread(function()
    -- تحميل الشاشات من قاعدة البيانات
    if Config.Database.enabled then
        LoadScreensFromDatabase()
    else
        -- تحميل الشاشات الافتراضية
        for _, screen in pairs(Config.DefaultScreens) do
            screens[screen.id] = screen
        end
    end
    
    print("^2[Cinema] ^7تم تحميل " .. GetScreensCount() .. " شاشة")
end)

-- معالجة الأحداث
RegisterNetEvent('cinema:requestData')
AddEventHandler('cinema:requestData', function()
    local source = source
    TriggerClientEvent('cinema:syncScreens', source, screens)
end)

RegisterNetEvent('cinema:updateScreen')
AddEventHandler('cinema:updateScreen', function(screenData)
    local source = source
    
    if not CheckPlayerPermission(source) then
        return
    end
    
    screens[screenData.id] = screenData
    
    -- حفظ في قاعدة البيانات
    if Config.Database.enabled then
        SaveScreenToDatabase(screenData)
    end
    
    -- مزامنة مع جميع اللاعبين
    TriggerClientEvent('cinema:syncScreens', -1, screens)
end)

RegisterNetEvent('cinema:deleteScreen')
AddEventHandler('cinema:deleteScreen', function(screenId)
    local source = source
    
    if not CheckPlayerPermission(source) then
        return
    end
    
    screens[screenId] = nil
    
    -- حذف من قاعدة البيانات
    if Config.Database.enabled then
        DeleteScreenFromDatabase(screenId)
    end
    
    -- مزامنة مع جميع اللاعبين
    TriggerClientEvent('cinema:syncScreens', -1, screens)
end)

RegisterNetEvent('cinema:playVideo')
AddEventHandler('cinema:playVideo', function(screenId, url)
    local source = source
    
    if not CheckPlayerPermission(source) then
        return
    end
    
    if screens[screenId] then
        screens[screenId].url = url
        screens[screenId].active = true
        
        -- مزامنة مع جميع اللاعبين
        TriggerClientEvent('cinema:syncVideo', -1, screenId, url)
        
        -- تسجيل السجل
        print("^3[Cinema] ^7اللاعب " .. GetPlayerName(source) .. " شغل فيديو في الشاشة " .. screenId)
    end
end)

RegisterNetEvent('cinema:stopVideo')
AddEventHandler('cinema:stopVideo', function(screenId)
    local source = source
    
    if not CheckPlayerPermission(source) then
        return
    end
    
    if screens[screenId] then
        screens[screenId].active = false
        
        -- مزامنة مع جميع اللاعبين
        TriggerClientEvent('cinema:syncStop', -1, screenId)
        
        -- تسجيل السجل
        print("^3[Cinema] ^7اللاعب " .. GetPlayerName(source) .. " أوقف فيديو في الشاشة " .. screenId)
    end
end)

RegisterNetEvent('cinema:setVolume')
AddEventHandler('cinema:setVolume', function(screenId, volume)
    local source = source
    
    if not CheckPlayerPermission(source) then
        return
    end
    
    if screens[screenId] then
        screens[screenId].volume = volume
        
        -- مزامنة مع جميع اللاعبين
        TriggerClientEvent('cinema:syncVolume', -1, screenId, volume)
    end
end)

-- دوال قاعدة البيانات
function LoadScreensFromDatabase()
    if not Config.Database.enabled then return end
    
    -- استخدم نظام قاعدة البيانات الخاص بك
    -- مثال باستخدام MySQL
    --[[
    MySQL.Async.fetchAll('SELECT * FROM ' .. Config.Database.table, {}, function(result)
        if result then
            for _, row in pairs(result) do
                local screen = {
                    id = row.id,
                    name = row.name,
                    coords = json.decode(row.coords),
                    rotation = json.decode(row.rotation),
                    scale = json.decode(row.scale),
                    url = row.url or "",
                    volume = row.volume or Config.DefaultVolume,
                    active = false
                }
                screens[screen.id] = screen
            end
        end
    end)
    ]]
end

function SaveScreenToDatabase(screenData)
    if not Config.Database.enabled then return end
    
    -- استخدم نظام قاعدة البيانات الخاص بك
    -- مثال باستخدام MySQL
    --[[
    MySQL.Async.execute('INSERT INTO ' .. Config.Database.table .. ' (id, name, coords, rotation, scale, url, volume) VALUES (@id, @name, @coords, @rotation, @scale, @url, @volume) ON DUPLICATE KEY UPDATE name = @name, coords = @coords, rotation = @rotation, scale = @scale, url = @url, volume = @volume', {
        ['@id'] = screenData.id,
        ['@name'] = screenData.name,
        ['@coords'] = json.encode(screenData.coords),
        ['@rotation'] = json.encode(screenData.rotation),
        ['@scale'] = json.encode(screenData.scale),
        ['@url'] = screenData.url,
        ['@volume'] = screenData.volume
    })
    ]]
end

function DeleteScreenFromDatabase(screenId)
    if not Config.Database.enabled then return end
    
    -- استخدم نظام قاعدة البيانات الخاص بك
    -- مثال باستخدام MySQL
    --[[
    MySQL.Async.execute('DELETE FROM ' .. Config.Database.table .. ' WHERE id = @id', {
        ['@id'] = screenId
    })
    ]]
end

-- دوال مساعدة
function CheckPlayerPermission(source)
    -- استبدل هذه الدالة بنظام الصلاحيات الخاص بك
    local playerGroup = GetPlayerGroup(source)
    return Config.Permissions[playerGroup] or false
end

function GetPlayerGroup(source)
    -- استبدل هذه الدالة بنظام الصلاحيات الخاص بك
    -- مثال:
    -- return exports.es_extended:getPlayerFromId(source).getGroup()
    return "admin" -- مثال
end

function GetScreensCount()
    local count = 0
    for _ in pairs(screens) do
        count = count + 1
    end
    return count
end

-- أوامر الكونسول
RegisterCommand('cinema_reload', function(source)
    if source == 0 then -- من الكونسول
        screens = {}
        LoadScreensFromDatabase()
        TriggerClientEvent('cinema:syncScreens', -1, screens)
        print("^2[Cinema] ^7تم إعادة تحميل الشاشات")
    end
end, true)

RegisterCommand('cinema_info', function(source)
    if source == 0 then -- من الكونسول
        print("^2[Cinema] ^7معلومات السكربت:")
        print("  - عدد الشاشات: " .. GetScreensCount())
        print("  - قاعدة البيانات: " .. (Config.Database.enabled and "مفعلة" or "معطلة"))
        print("  - الحد الأقصى للشاشات: " .. Config.MaxScreens)
    end
end, true)