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
    -- เมืองวาเลนไทน์ (Valentine)
    { x = -345.84, y = 792.88, z = 116.12, heading = 3.76 },
    -- เมืองโรดส์ (Rhodes) 
    { x = 1310.7878, y = -1295.0763, z = 75.8311, heading = 73.9208 },
    -- เมืองแอนเนสเบิร์ก (Annesburg)
    { x = 2932.9998, y = 1308.3740, z = 44.4918, heading = 258.1208 },
    -- เอเมอรัลด์แรนช์ (Emerald Ranch)
    { x = 1522.05, y = 438.76,  z = 90.68, heading = 180.0 },
    -- เพิ่มจุดใหม่ได้ตามต้องการ
}
