Config = {}

Config.npcs = {
    {
        name = "Mark",
        text = "ฉันรู้จักนักล่าด้วยเช่นกัน.",
        job = "Hunter",
        ped = "cs_cabaretmc",
        coords = vector4(-469.08, -111.4, 40.64, 240.96),
        options = {
            {
                label = "ตกลง",
                event = "dailyreward",
                type = "command",
                args = {1} 
            },
             {
                label = "ยกเลิก",
                event = "DailyReward:hideUI",
                type = "client",
                args = {1}
            },
        }
    },
}