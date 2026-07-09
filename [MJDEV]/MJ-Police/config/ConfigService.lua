ConfigService = {}

ConfigService.CommunityServiceSettings = {
    minigame = false,               -- ใช้มินิเกม Syn หรือไม่
    communityservicetimer = 10,    -- จำนวนวินาทีที่ผู้เล่นต้องกลับไปยังตำแหน่ง
    communityservicedistance = 25, -- ระยะทางก่อนที่จะมีการเตือนให้กลับไปยังพื้นที่บริการชุมชน
    leftserviceamount = 2,         -- จำนวนนาทีที่จะนำผู้เล่นไปคุกหากหนีจากบริการชุมชน
}

-- บริการชุมชนตั้งอยู่ใน Blackwater หากอยู่ไกลเกินไปจะถูกนำไปคุก คุณต้องพาไปด้วยตัวเอง
ConfigService.construction = {
    { x = -838.37, y = -1273.13, z = 43.53 },
    { x = -832.66, y = -1273.21, z = 43.58 },
    { x = -828.88, y = -1268.5,  z = 43.63 },
    { x = -826.92, y = -1277.46, z = 43.61 },
}
