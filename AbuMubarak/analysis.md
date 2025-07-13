# تحليل سكربت CinemaPad

## مقدمة

تم إنشاء البنية الأساسية لسكربت CinemaPad، والذي يهدف إلى توفير واجهة سينما داخل لعبة FiveM بتصميم مستوحى من iPad. يتكون السكربت من ملفات جانب العميل (client-side)، وجانب الخادم (server-side)، وملفات واجهة المستخدم (NUI). يهدف هذا التحليل إلى مراجعة الكود الحالي، تحديد أي مشكلات محتملة، واقتراح تحسينات وميزات جديدة لتعزيز وظائف السكربت وتجربة المستخدم.

## نظرة عامة على مكونات السكربت

يتكون السكربت من المكونات الرئيسية التالية:

*   **`config.lua`**: ملف الإعدادات الذي يحتوي على المتغيرات القابلة للتكوين مثل مجموعة المسؤولين.
*   **`client.lua`**: يتعامل مع منطق العميل، بما في ذلك تسجيل الأمر `/cinema`، تبديل رؤية واجهة المستخدم (UI)، والتفاعل مع نظام الصوت `xsound` لتشغيل، إيقاف، والتحكم في مستوى الصوت.
*   **`server.lua`**: يتعامل مع منطق الخادم، ويتحقق من أذونات اللاعبين قبل السماح لهم بتشغيل أمر `/cinema`.
*   **`fxmanifest.lua`**: ملف تعريف المورد الخاص بـ FiveM، والذي يحدد إصدار FiveM، الألعاب المدعومة، والملفات التي يجب تحميلها.
*   **`html/` (مجلد NUI)**: يحتوي على ملفات واجهة المستخدم:
    *   **`index.html`**: هيكل HTML لواجهة المستخدم.
    *   **`style.css`**: أنماط CSS لتصميم الواجهة (iPad-style, dark neon blue, iOS 17 look).
    *   **`script.js`**: منطق JavaScript لواجهة المستخدم، بما في ذلك معالجة الإدخالات، إرسال الطلبات إلى جانب العميل، والتحكم في عناصر الواجهة.

## تحليل الملفات واقتراحات التحسين

### 1. `config.lua`

**الحالة الحالية:**

```lua
-- ملف الإعدادات لسكربت CinemaPad

Config = {}

-- المجموعة الإدارية التي يمكنها استخدام أمر /cinema
Config.AdminGroup = "admin" -- يمكنك تغيير هذا إلى المجموعة الخاصة بك (على سبيل المثال: "superadmin", "mod")

-- إعدادات أخرى (يمكن إضافتها لاحقًا)
```

**التحليل والتحسينات المقترحة:**

*   **المرونة في تحديد المجموعات:** حاليًا، `Config.AdminGroup` يسمح بتحديد مجموعة واحدة فقط. قد يكون من المفيد السماح بتحديد عدة مجموعات إدارية يمكنها استخدام الأمر. يمكن تحقيق ذلك باستخدام جدول (table) بدلاً من سلسلة نصية (string).
*   **إعدادات الصوت الافتراضية:** يمكن إضافة إعدادات افتراضية لمستوى الصوت الأولي، أو ما إذا كان الصوت يجب أن يكون مكتومًا عند بدء التشغيل.
*   **إعدادات واجهة المستخدم:** يمكن إضافة خيارات لتخصيص مظهر الواجهة (مثل الألوان، الخطوط) أو تمكين/تعطيل ميزات معينة من خلال الإعدادات.
*   **رسائل قابلة للتكوين:** يمكن نقل رسائل الدردشة (مثل رسالة 


عدم الإذن) إلى ملف `config.lua` لجعلها قابلة للتكوين بسهولة دون الحاجة لتعديل الكود.

**مثال على التحسين المقترح لـ `config.lua`:**

```lua
Config = {}

-- المجموعات الإدارية التي يمكنها استخدام أمر /cinema
Config.AdminGroups = {"admin", "superadmin"} -- يمكن إضافة المزيد من المجموعات هنا

-- مستوى الصوت الافتراضي عند تشغيل الصوت لأول مرة (بين 0.0 و 1.0)
Config.DefaultVolume = 0.5

-- رسائل النظام
Config.Messages = {
    NoPermission = "^1خطأ:^0 ليس لديك الإذن لاستخدام هذا الأمر.",
    CommandUsedInConsole = "لا يمكن استخدام هذا الأمر من الكونسول."
}
```

### 2. `client.lua`

**الحالة الحالية:**

```lua
--[[ client.lua لسكربت CinemaPad ]]--

-- متغير لتتبع حالة الواجهة (مفتوحة/مغلقة)
local isUiVisible = false

-- تسجيل الأمر /cinema
RegisterCommand("cinema", function(source, args, rawCommand)
    -- تبديل حالة الواجهة
    isUiVisible = not isUiVisible
    -- إرسال رسالة إلى واجهة المستخدم لتحديث حالتها
    SendNUIMessage({ type = "ui", status = isUiVisible })
    -- التركيز على واجهة المستخدم إذا كانت مفتوحة
    SetNuiFocus(isUiVisible, isUiVisible)
end, false) -- `false` هنا تعني أن أي شخص يمكنه تشغيل الأمر من جانب العميل، ولكن الخادم سيتحقق من الأذونات

-- استقبال الرسائل من واجهة المستخدم
RegisterNUICallback(\'close\', function(data, cb)
    isUiVisible = false
    SetNuiFocus(false, false)
    cb(\'ok\')
end)

RegisterNUICallback(\'play\', function(data, cb)
    if data.url then
        -- تشغيل الصوت باستخدام xsound
        exports.xsound:playSound(data.url, "{}")
    end
    cb(\'ok\')
end)

RegisterNUICallback(\'volume\', function(data, cb)
    if data.volume then
        -- التحكم في مستوى الصوت باستخدام xsound
        exports.xsound:setVolume(data.volume)
    end
    cb(\'ok\')
end)

RegisterNUICallback(\'stop\', function(data, cb)
    -- إيقاف الصوت باستخدام xsound
    exports.xsound:stopSound()
    cb(\'ok\')
end)
```

**التحليل والتحسينات المقترحة:**

*   **التحقق من الأذونات على جانب الخادم:** حاليًا، يتم تسجيل الأمر `/cinema` على جانب العميل مع `false` كآخر وسيط، مما يعني أنه يمكن لأي شخص تشغيله. بينما يتم التحقق من الأذونات على جانب الخادم، فمن الأفضل أن يتم تسجيل الأمر على جانب الخادم فقط باستخدام `true` كآخر وسيط في `RegisterCommand` لمنع اللاعبين غير المصرح لهم من محاولة فتح الواجهة من الأساس. هذا يقلل من حركة المرور غير الضرورية بين العميل والخادم.
*   **معالجة الأخطاء:** لا يوجد حاليًا أي معالجة للأخطاء إذا فشل `exports.xsound:playSound` أو `exports.xsound:setVolume`. يمكن إضافة رسائل خطأ للمستخدم أو تسجيل الأخطاء في الكونسول.
*   **التحقق من صحة الرابط:** يجب إضافة منطق للتحقق من أن الرابط المدخل هو رابط YouTube أو رابط صوتي صالح قبل محاولة تشغيله. يمكن استخدام تعبيرات منتظمة (regular expressions) للتحقق من تنسيق الرابط.
*   **تخزين حالة الصوت:** قد يكون من المفيد تخزين حالة الصوت (مثل الرابط الذي يتم تشغيله حاليًا، مستوى الصوت) على جانب العميل أو الخادم لضمان استمرارية التشغيل إذا قام اللاعب بإغلاق وفتح الواجهة مرة أخرى، أو إذا غادر ثم عاد إلى اللعبة.
*   **تحديد نطاق الصوت:** حاليًا، `exports.xsound:playSound` يستخدم `{}` كمعامل ثانٍ، مما يعني أن الصوت يتم تشغيله عالميًا. يمكن إضافة خيار لتحديد نطاق الصوت (على سبيل المثال، صوت مكاني، أو صوت يقتصر على منطقة معينة) بناءً على إعدادات السكربت أو اختيار المستخدم.
*   **إضافة ميزات التحكم في التشغيل:** يمكن إضافة ميزات مثل الإيقاف المؤقت/الاستئناف (pause/resume) أو التقديم/الترجيع (seek) إذا كان `xsound` يدعمها.

**مثال على التحسين المقترح لـ `client.lua` (جزء من RegisterCommand):**

```lua
-- تسجيل الأمر /cinema (يتم تسجيله على جانب الخادم فقط للتحقق من الأذونات)
-- RegisterCommand("cinema", function(source, args, rawCommand)
--     -- هذا الجزء سيتم نقله إلى server.lua ليتم التحكم فيه بالكامل من هناك
-- end, false)

-- استقبال حدث تبديل الواجهة من الخادم
RegisterNetEvent("cinemapad:toggleUI")
AddEventHandler("cinemapad:toggleUI", function()
    isUiVisible = not isUiVisible
    SendNUIMessage({ type = "ui", status = isUiVisible })
    SetNuiFocus(isUiVisible, isUiVisible)
end)
```

### 3. `server.lua`

**الحالة الحالية:**

```lua
--[[ server.lua لسكربت CinemaPad ]]--

-- جلب الإعدادات من config.lua
local Config = module("config", true)

-- تسجيل الأمر /cinema على جانب الخادم للتحقق من الأذونات
RegisterCommand("cinema", function(source, args, rawCommand)
    local player = source
    if player == 0 then
        print("لا يمكن استخدام هذا الأمر من الكونسول.")
        return
    end

    -- التحقق من مجموعة اللاعب
    -- (هذا مثال، قد تحتاج إلى تعديله ليتناسب مع نظام الأذونات الخاص بك)
    -- على سبيل المثال، إذا كنت تستخدم ESX أو QBCore، ستحتاج إلى استخدام وظائفهم للتحقق من المجموعة.
    -- هنا نفترض وجود وظيفة وهمية `IsPlayerInAdminGroup`
    if IsPlayerInAdminGroup(player, Config.AdminGroup) then
        TriggerClientEvent("cinemapad:toggleUI", player)
    else
        TriggerClientEvent("chat:addMessage", player, {
            args = {"^1خطأ:^0 ليس لديك الإذن لاستخدام هذا الأمر."}
        })
    end
end, false)

-- وظيفة وهمية للتحقق من مجموعة اللاعب (تحتاج إلى استبدالها بوظيفتك الحقيقية)
function IsPlayerInAdminGroup(player, groupName)
    -- هنا يجب أن تضع منطق التحقق من المجموعة الفعلي الخاص بك.
    -- على سبيل المثال، إذا كنت تستخدم ESX:
    -- local xPlayer = ESX.GetPlayerFromId(player)
    -- if xPlayer and xPlayer.getGroup() == groupName then
    --     return true
    -- end

    -- أو إذا كنت تستخدم QBCore:
    -- local Player = QBCore.Functions.GetPlayer(player)
    -- if Player and Player.PlayerData.job.name == groupName then -- مثال على التحقق من الوظيفة كـ admin
    --     return true
    -- end

    -- للمثال، سنعيد true دائمًا للسماح بالاختبار، ولكن يجب تغيير هذا!
    return true
end

-- استقبال حدث تبديل الواجهة من العميل (للتأكد من أن الأمر تم تشغيله من قبل لاعب مصرح له)
RegisterNetEvent("cinemapad:toggleUI")
AddEventHandler("cinemapad:toggleUI", function()
    local player = source
    -- لا حاجة للتحقق من الأذونات هنا مرة أخرى، فقد تم التحقق منها بالفعل في الأمر.
    -- يمكن إضافة منطق إضافي هنا إذا لزم الأمر.
end)
```

**التحليل والتحسينات المقترحة:**

*   **تطبيق نظام الأذونات الفعلي:** وظيفة `IsPlayerInAdminGroup` هي حاليًا وظيفة وهمية تعيد `true` دائمًا. يجب استبدالها بمنطق تحقق حقيقي يتكامل مع نظام الأذونات المستخدم في الخادم (مثل ESX، QBCore، أو نظام أذونات مخصص). هذا هو أهم تحسين لضمان أمان السكربت.
*   **استخدام `Config.AdminGroups`:** إذا تم تعديل `config.lua` للسماح بمجموعات متعددة، فيجب تحديث `server.lua` للتحقق مما إذا كان اللاعب ينتمي إلى أي من المجموعات المحددة في `Config.AdminGroups`.
*   **رسائل الخطأ:** استخدام `Config.Messages.NoPermission` لرسالة الخطأ بدلاً من السلسلة النصية المباشرة يجعل الرسالة قابلة للتكوين.
*   **تسجيل الأوامر:** كما ذكر في `client.lua`، من الأفضل تسجيل الأمر `/cinema` على جانب الخادم فقط باستخدام `true` كآخر وسيط في `RegisterCommand`، ثم استخدام `TriggerClientEvent` لفتح الواجهة على جانب العميل بعد التحقق من الأذونات.

**مثال على التحسين المقترح لـ `server.lua` (وظيفة `IsPlayerInAdminGroup` مع ESX):**

```lua
-- وظيفة للتحقق من مجموعة اللاعب (مثال مع ESX)
function IsPlayerInAdminGroup(player, adminGroups)
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer then
        local playerGroup = xPlayer.getGroup()
        for i=1, #adminGroups do
            if playerGroup == adminGroups[i] then
                return true
            end
        end
    end
    return false
end

-- تحديث RegisterCommand لاستخدام Config.Messages
RegisterCommand("cinema", function(source, args, rawCommand)
    local player = source
    if player == 0 then
        print(Config.Messages.CommandUsedInConsole)
        return
    end

    if IsPlayerInAdminGroup(player, Config.AdminGroups) then -- استخدام Config.AdminGroups
        TriggerClientEvent("cinemapad:toggleUI", player)
    else
        TriggerClientEvent("chat:addMessage", player, {
            args = {Config.Messages.NoPermission}
        })
    end
end, true) -- `true` هنا تعني أن الأمر يتم تسجيله على جانب الخادم فقط
```

### 4. `html/index.html`

**الحالة الحالية:**

```html
<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CinemaPad</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div id="ipad-container" class="hidden">
        <div class="ipad-header">
            <div class="camera"></div>
            <div class="time">9:41</div>
            <div class="island"></div>
        </div>
        <div class="ipad-content">
            <h1>CinemaPad</h1>
            <p>أدخل رابط يوتيوب أو ملف صوتي لتشغيله في اللعبة.</p>
            <input type="text" id="media-url" placeholder="https://www.youtube.com/watch?v=...">
            <div class="controls">
                <button id="play-btn">تشغيل</button>
                <button id="stop-btn">إيقاف</button>
            </div>
            <div class="volume-control">
                <label for="volume-slider">مستوى الصوت</label>
                <input type="range" id="volume-slider" min="0" max="1" step="0.01" value="0.5">
                <button id="mute-btn">كتم</button>
            </div>
        </div>
        <div class="ipad-footer">
            <button id="close-btn">إغلاق</button>
        </div>
    </div>
    <script src="script.js"></script>
</body>
</html>
```

**التحليل والتحسينات المقترحة:**

*   **تحسين تجربة المستخدم (UX):**
    *   **مؤشر التحميل:** إضافة مؤشر تحميل مرئي عند محاولة تشغيل رابط، لإعلام المستخدم بأن العملية جارية.
    *   **رسائل الحالة:** عرض رسائل للمستخدم (مثل 


رسالة نجاح التشغيل، أو رسالة خطأ إذا كان الرابط غير صالح) داخل الواجهة بدلاً من رسائل الدردشة فقط.
    *   **قائمة الروابط المحفوظة:** يمكن إضافة ميزة لحفظ الروابط التي تم تشغيلها مسبقًا، بحيث يمكن للمستخدمين إعادة تشغيلها بسهولة دون الحاجة إلى لصقها مرة أخرى.
    *   **التحكم في التشغيل/الإيقاف المؤقت:** إضافة زر للإيقاف المؤقت (Pause) والاستئناف (Resume) إذا كان `xsound` يدعم ذلك.
*   **التحقق من صحة الإدخال:** يمكن إضافة التحقق من صحة الرابط على جانب العميل قبل إرساله إلى جانب العميل، مما يوفر موارد الشبكة ويحسن الاستجابة.
*   **الوصولية:** التأكد من أن الواجهة قابلة للاستخدام بواسطة لوحة المفاتيح فقط (باستخدام `tabindex` وغيرها).

### 5. `html/style.css`

**الحالة الحالية:**

```css
body {
    margin: 0;
    overflow: hidden; /* لمنع ظهور أشرطة التمرير */
    font-family: \'Segoe UI\', Tahoma, Geneva, Verdana, sans-serif;
    background-color: rgba(0, 0, 0, 0.5); /* خلفية شفافة قليلاً عند فتح الـ UI */
}

#ipad-container {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 800px; /* حجم iPad */
    height: 600px;
    background-color: #1a1a2e; /* لون داكن */
    border-radius: 40px; /* حواف مستديرة */
    box-shadow: 0 0 50px rgba(0, 255, 255, 0.5); /* ظل نيون أزرق */
    border: 5px solid #00ffff; /* حدود نيون */
    display: flex;
    flex-direction: column;
    overflow: hidden;
    color: #e0e0e0;
}

.hidden {
    display: none !important;
}

.ipad-header {
    background-color: #0f0f1a;
    padding: 15px 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #00ffff;
}

.camera {
    width: 20px;
    height: 20px;
    background-color: #00ffff;
    border-radius: 50%;
}

.time {
    font-size: 1.2em;
    font-weight: bold;
    color: #00ffff;
}

.island {
    width: 60px;
    height: 25px;
    background-color: #00ffff;
    border-radius: 15px;
}

.ipad-content {
    flex-grow: 1;
    padding: 30px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
}

.ipad-content h1 {
    color: #00ffff;
    margin-bottom: 20px;
    font-size: 2.5em;
}

.ipad-content p {
    margin-bottom: 30px;
    font-size: 1.1em;
}

#media-url {
    width: 80%;
    padding: 15px;
    margin-bottom: 20px;
    border-radius: 10px;
    border: 2px solid #00ffff;
    background-color: #0f0f1a;
    color: #e0e0e0;
    font-size: 1em;
}

.controls button,
.ipad-footer button {
    background-color: #00ffff;
    color: #1a1a2e;
    border: none;
    padding: 12px 25px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 1.1em;
    font-weight: bold;
    transition: background-color 0.3s ease;
    margin: 0 10px;
}

.controls button:hover,
.ipad-footer button:hover {
    background-color: #00e6e6;
}

.volume-control {
    margin-top: 30px;
    width: 80%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.volume-control label {
    margin-right: 15px;
    font-size: 1.1em;
    color: #00ffff;
}

#volume-slider {
    width: 60%;
    -webkit-appearance: none;
    height: 10px;
    border-radius: 5px;
    background: #0f0f1a;
    outline: none;
    opacity: 0.7;
    transition: opacity .2s;
}

#volume-slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: #00ffff;
    cursor: pointer;
}

#volume-slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: #00ffff;
    cursor: pointer;
}

#mute-btn {
    margin-left: 15px;
}

.ipad-footer {
    background-color: #0f0f1a;
    padding: 15px 20px;
    display: flex;
    justify-content: center;
    border-top: 2px solid #00ffff;
}
```

**التحليل والتحسينات المقترحة:**

*   **التصميم المتجاوب (Responsive Design):** حاليًا، الواجهة لها أبعاد ثابتة (`width: 800px; height: 600px;`). لجعلها تبدو جيدة على شاشات مختلفة الأحجام (خاصة إذا كان اللاعبون يستخدمون دقة شاشة مختلفة)، يجب استخدام وحدات نسبية (مثل `vw`, `vh`, `%`) أو استعلامات الوسائط (media queries) لجعل التصميم متجاوبًا.
*   **الخطوط (Fonts):** استخدام خطوط مخصصة (مثل خطوط Google Fonts) يمكن أن يعزز المظهر الجمالي للواجهة ويجعلها تبدو أكثر احترافية وتطابقًا مع تصميم iOS 17.
*   **الرسوم المتحركة (Animations):** إضافة رسوم متحركة بسيطة عند فتح/إغلاق الواجهة أو عند التفاعل مع الأزرار يمكن أن يحسن تجربة المستخدم ويجعل الواجهة أكثر حيوية.
*   **تحسينات iOS 17:** يمكن البحث عن تفاصيل تصميم iOS 17 (مثل تأثيرات الضبابية، الأيقونات، التدرجات اللونية) وتطبيقها لتعزيز المظهر 


الجمالي.

### 6. `html/script.js`

**الحالة الحالية:**

```javascript
// script.js لسكربت CinemaPad

const ipadContainer = document.getElementById("ipad-container");
const mediaUrlInput = document.getElementById("media-url");
const playBtn = document.getElementById("play-btn");
const stopBtn = document.getElementById("stop-btn");
const volumeSlider = document.getElementById("volume-slider");
const muteBtn = document.getElementById("mute-btn");
const closeBtn = document.getElementById("close-btn");

let isMuted = false;
let lastVolume = 0.5; // لتخزين آخر مستوى صوت قبل الكتم

// استقبال الرسائل من جانب العميل (client.lua)
window.addEventListener("message", function(event) {
    const data = event.data;
    if (data.type === "ui") {
        if (data.status) {
            ipadContainer.classList.remove("hidden");
        } else {
            ipadContainer.classList.add("hidden");
        }
    }
});

// إغلاق الواجهة عند الضغط على زر الإغلاق
closeBtn.addEventListener("click", function() {
    ipadContainer.classList.add("hidden");
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({}),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// تشغيل الصوت
playBtn.addEventListener("click", function() {
    const url = mediaUrlInput.value;
    if (url) {
        fetch(`https://${GetParentResourceName()}/play`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({ url: url }),
        }).then(resp => resp.json()).then(resp => console.log(resp));
    }
});

// إيقاف الصوت
stopBtn.addEventListener("click", function() {
    fetch(`https://${GetParentResourceName()}/stop`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({}),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// التحكم في مستوى الصوت
volumeSlider.addEventListener("input", function() {
    const volume = parseFloat(volumeSlider.value);
    lastVolume = volume; // تحديث آخر مستوى صوت
    if (isMuted && volume > 0) {
        isMuted = false;
        muteBtn.textContent = "كتم";
    }
    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({ volume: volume }),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// كتم/إلغاء كتم الصوت
muteBtn.addEventListener("click", function() {
    if (isMuted) {
        // إلغاء الكتم
        volumeSlider.value = lastVolume; // استعادة آخر مستوى صوت
        isMuted = false;
        muteBtn.textContent = "كتم";
    } else {
        // كتم الصوت
        lastVolume = parseFloat(volumeSlider.value); // حفظ مستوى الصوت الحالي
        volumeSlider.value = 0; // تعيين مستوى الصوت إلى صفر
        isMuted = true;
        muteBtn.textContent = "إلغاء الكتم";
    }
    // إرسال مستوى الصوت الجديد (0 أو lastVolume) إلى العميل
    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({ volume: parseFloat(volumeSlider.value) }),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// تحديث الوقت في الواجهة (مثال بسيط)
function updateTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, \'0\');
    const minutes = now.getMinutes().toString().padStart(2, \'0\');
    document.querySelector(".time").textContent = `${hours}:${minutes}`;
}
setInterval(updateTime, 1000); // تحديث كل ثانية
updateTime(); // تحديث فوري عند التحميل
```

**التحليل والتحسينات المقترحة:**

*   **التحقق من صحة الرابط:** يجب إضافة منطق للتحقق من أن الرابط المدخل هو رابط YouTube أو رابط صوتي صالح قبل إرساله إلى جانب العميل. يمكن استخدام تعبيرات منتظمة (regular expressions) للتحقق من تنسيق الرابط. هذا يمنع إرسال طلبات غير صالحة إلى جانب العميل.
*   **معالجة الأخطاء والرسائل للمستخدم:** حاليًا، يتم فقط تسجيل الاستجابة من `fetch` في الكونسول. يجب عرض رسائل واضحة للمستخدم داخل الواجهة حول حالة التشغيل (نجاح، فشل، رابط غير صالح).
*   **تحسين وظيفة كتم الصوت:** يمكن تحسين منطق كتم الصوت بحيث يتم إرسال مستوى الصوت الفعلي (0 أو `lastVolume`) إلى جانب العميل بدلاً من الاعتماد على `volumeSlider.value` بعد التغيير.
*   **إدارة حالة الواجهة:** يمكن استخدام مكتبة إدارة حالة بسيطة (مثل Redux أو Context API إذا كان المشروع سيكبر) لجعل إدارة حالة الواجهة أكثر تنظيمًا، على الرغم من أن هذا قد يكون مبالغًا فيه لسكربت صغير.
*   **تحديد نطاق الصوت:** إذا تم إضافة خيار لتحديد نطاق الصوت في `client.lua`، فيجب إضافة عناصر تحكم في الواجهة للسماح للمستخدم باختيار نوع الصوت (عالمي، مكاني، إلخ).
*   **تحسين تجربة المستخدم (UX):**
    *   **زر الإدخال (Enter Key):** السماح للمستخدم بالضغط على مفتاح Enter في حقل الإدخال لتشغيل الصوت بدلاً من النقر على زر 


التشغيل.
    *   **مسح حقل الإدخال:** مسح حقل الإدخال تلقائيًا بعد تشغيل الصوت بنجاح.

### 7. `fxmanifest.lua`

**الحالة الحالية:**

```lua
-- fxmanifest.lua لسكربت CinemaPad

fx_version \'cerulean\'
games { \'gta5\' }

author \'Manus\'
description \'FiveM CinemaPad Script with iPad-style UI\'

-- ملفات جانب العميل
client_scripts {
    \'client.lua\'
}

-- ملفات جانب الخادم
server_scripts {
    \'@config.lua\', -- تأكد من تحميل ملف الإعدادات أولاً
    \'server.lua\'
}

-- ملفات واجهة المستخدم (NUI)
ui_page \'html/index.html\'

files {
    \'html/index.html\',
    \'html/style.css\',
    \'html/script.js\'
}

-- لضمان عمل exports.xsound، يجب أن يكون xsound موردًا آخر مثبتًا.
-- تأكد من أن xsound موجود في مجلد resources الخاص بك.
```

**التحليل والتحسينات المقترحة:**

*   **التبعيات (Dependencies):** يجب الإشارة بوضوح إلى أن `xsound` هو مورد مطلوب (dependency). يمكن إضافة `dependency 'xsound'` إلى `fxmanifest.lua` لضمان تحميله قبل CinemaPad. هذا يساعد في منع الأخطاء إذا لم يتم بدء `xsound` بشكل صحيح.
*   **تحديد إصدار `fx_version`:** `cerulean` هو إصدار قديم نسبيًا. يمكن التفكير في الترقية إلى إصدار أحدث (مثل `bodacious` أو `gta_defines`) للاستفادة من الميزات والتحسينات الجديدة التي يوفرها FiveM، مع الأخذ في الاعتبار التوافق مع الموارد الأخرى.

## ملخص التحسينات والميزات المقترحة

بناءً على التحليل أعلاه، إليك ملخص للتحسينات والميزات المقترحة لسكربت CinemaPad:

### تحسينات أساسية (موصى بها بشدة):

1.  **نظام الأذونات:**
    *   تعديل `config.lua` للسماح بتحديد مجموعات إدارية متعددة (`Config.AdminGroups`).
    *   تعديل `server.lua` لتطبيق وظيفة `IsPlayerInAdminGroup` حقيقية تتكامل مع نظام الأذونات الخاص بالخادم (ESX/QBCore/مخصص).
    *   تسجيل الأمر `/cinema` على جانب الخادم فقط (`RegisterCommand` مع `true`).
2.  **التحقق من صحة الرابط:**
    *   إضافة منطق للتحقق من صحة روابط YouTube/الصوت في `html/script.js` قبل إرسالها إلى جانب العميل.
    *   عرض رسائل خطأ واضحة للمستخدم في الواجهة إذا كان الرابط غير صالح.
3.  **رسائل قابلة للتكوين:** نقل رسائل الدردشة إلى `config.lua` لجعلها قابلة للتعديل بسهولة.
4.  **التبعيات:** إضافة `dependency 'xsound'` إلى `fxmanifest.lua`.

### تحسينات تجربة المستخدم (UX):

1.  **مؤشر التحميل:** إضافة مؤشر تحميل مرئي في الواجهة عند تشغيل الصوت.
2.  **رسائل الحالة:** عرض رسائل نجاح/فشل التشغيل داخل الواجهة.
3.  **التحكم في التشغيل/الإيقاف المؤقت:** إضافة زر للإيقاف المؤقت/الاستئناف إذا كان `xsound` يدعم ذلك.
4.  **التحكم في مستوى الصوت:** تحسين منطق كتم الصوت في `html/script.js`.
5.  **التصميم المتجاوب:** جعل واجهة المستخدم متجاوبة مع أحجام الشاشات المختلفة.
6.  **الخطوط والرسوم المتحركة:** استخدام خطوط مخصصة وإضافة رسوم متحركة بسيطة لتحسين المظهر.

### ميزات إضافية:

1.  **تحديد نطاق الصوت:** إضافة خيار لتحديد نطاق الصوت (عالمي، مكاني) في `client.lua` وعناصر تحكم في الواجهة.
2.  **قائمة الروابط المحفوظة:** ميزة لحفظ الروابط التي تم تشغيلها مسبقًا.
3.  **تخزين حالة الصوت:** حفظ حالة الصوت (الرابط، مستوى الصوت) لضمان استمرارية التشغيل.

## الخطوات التالية

الخطوة التالية هي البدء في تطبيق هذه التحسينات والميزات. هل ترغب في البدء بتطبيق التحسينات الأساسية أولاً، أم لديك ميزات معينة ترغب في البدء بها؟ يرجى إخباري بتفضيلاتك.

