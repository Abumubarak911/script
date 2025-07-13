-- قاعدة بيانات سكربت السينما
-- استخدم هذا الملف إذا كنت تريد حفظ الشاشات في قاعدة البيانات

CREATE TABLE IF NOT EXISTS `cinema_screens` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `coords` text NOT NULL,
    `rotation` text NOT NULL,
    `scale` text NOT NULL,
    `url` text DEFAULT NULL,
    `volume` float DEFAULT 0.5,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- بيانات تجريبية (اختياري)
INSERT INTO `cinema_screens` (`name`, `coords`, `rotation`, `scale`, `url`, `volume`) VALUES
('شاشة الساحة الرئيسية', '{"x":-1678.0,"y":-1103.0,"z":13.0}', '{"x":0.0,"y":0.0,"z":0.0}', '{"x":10.0,"y":5.0,"z":1.0}', '', 0.5),
('شاشة المطار', '{"x":-1037.0,"y":-2738.0,"z":20.0}', '{"x":0.0,"y":0.0,"z":90.0}', '{"x":8.0,"y":4.0,"z":1.0}', '', 0.3);

-- جدول سجلات الاستخدام (اختياري)
CREATE TABLE IF NOT EXISTS `cinema_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `screen_id` int(11) NOT NULL,
    `player_id` varchar(50) NOT NULL,
    `player_name` varchar(255) NOT NULL,
    `action` varchar(50) NOT NULL,
    `details` text DEFAULT NULL,
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `screen_id` (`screen_id`),
    KEY `player_id` (`player_id`),
    CONSTRAINT `cinema_logs_ibfk_1` FOREIGN KEY (`screen_id`) REFERENCES `cinema_screens` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- جدول الصلاحيات (اختياري)
CREATE TABLE IF NOT EXISTS `cinema_permissions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_id` varchar(50) NOT NULL,
    `permission_level` enum('admin','moderator','vip','user') DEFAULT 'user',
    `granted_by` varchar(50) DEFAULT NULL,
    `granted_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- إضافة أدمن افتراضي (غير الـ identifier)
INSERT INTO `cinema_permissions` (`player_id`, `permission_level`) VALUES
('steam:110000112345678', 'admin'); -- غير هذا بالـ identifier الخاص بك