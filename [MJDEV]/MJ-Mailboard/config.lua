Config = {}
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 

-- CREATE TABLE IF NOT EXISTS `mailboard_posts` (
--     `id` INT NOT NULL AUTO_INCREMENT,
--     `identifier` VARCHAR(64) NOT NULL,
--     `charname` VARCHAR(100) NOT NULL,
--     `text` TEXT NOT NULL,
--     `image` TEXT,
--     `time` INT NOT NULL,
--     PRIMARY KEY (`id`)
-- );

Config.BoardModel = "mp005_p_mp_bountyboard02x" -- โมเดลกระดาน สามารถเปลี่ยนเป็นโมเดลอื่นที่เหมาะสม
Config.InteractDistance = 3.0 -- ✅ ระยะที่สามารถกดปุ่ม E เพื่อเปิดบอร์ดได้

Config.BoardLocations = {
    { x = -345.84, y = 792.88, z = 116.12, heading = 3.76 }, 
    { x = 1322.01, y = -1321.74, z = 77.89, heading = 180.0 },
    -- เพิ่มจุดใหม่ได้ตามต้องการ
}
