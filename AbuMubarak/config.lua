Config = {}

-- إعدادات عامة
Config.Command = 'cinema' -- أمر فتح القائمة
Config.MaxScreens = 10 -- حد أقصى للشاشات
Config.DefaultVolume = 0.5 -- مستوى الصوت الافتراضي
Config.MaxDistance = 50.0 -- المسافة القصوى لسماع الصوت

-- صلاحيات التحكم
Config.Permissions = {
    admin = true, -- الأدمن يقدر يتحكم
    moderator = true, -- المودريتر يقدر يتحكم
    vip = false, -- الـ VIP ما يقدر يتحكم
    user = false -- المستخدم العادي ما يقدر يتحكم
}

-- إعدادات قاعدة البيانات
Config.Database = {
    enabled = true,
    table = 'cinema_screens'
}

-- الشاشات المحفوظة مسبقاً
Config.DefaultScreens = {
    {
        id = 1,
        name = "شاشة الساحة الرئيسية",
        coords = vector3(-1678.0, -1103.0, 13.0),
        rotation = vector3(0.0, 0.0, 0.0),
        scale = vector3(10.0, 5.0, 1.0),
        url = "",
        volume = 0.5,
        active = false
    },
    {
        id = 2,
        name = "شاشة المطار",
        coords = vector3(-1037.0, -2738.0, 20.0),
        rotation = vector3(0.0, 0.0, 90.0),
        scale = vector3(8.0, 4.0, 1.0),
        url = "",
        volume = 0.3,
        active = false
    }
}

-- رسائل النظام
Config.Messages = {
    no_permission = "~r~ليس لديك صلاحية للتحكم في السينما",
    screen_added = "~g~تم إضافة شاشة جديدة",
    screen_removed = "~r~تم حذف الشاشة",
    screen_updated = "~y~تم تحديث الشاشة",
    max_screens = "~r~وصلت للحد الأقصى من الشاشات",
    invalid_url = "~r~رابط غير صالح",
    cinema_opened = "~g~تم فتح قائمة السينما",
    cinema_closed = "~y~تم إغلاق قائمة السينما"
}