Config = {}

Config['UseFilter'] = true
Config['Webhook'] = {
    ['BWPolice'] = "https://discord.com/api/webhooks/your-police-webhook",
    ['doctor'] = "https://discord.com/api/webhooks/your-doctor-webhook",
}

Config['Duty'] = {
    ['offpolice'] = {
        ['Model'] = "A_M_M_BiVWorker_01",
        ['img'] = '/html/img/logo.png',
        ['Text'] = "จุดเข้า-ออกเวร: ตำรวจ",
        ['coords'] = {x = -277.2, y = 801.24, z = 119.36, h = 188.84},
        ['Distance'] = 1.5,
        ['Job'] = "police",
        ['offJob'] = "offpolice",
    },
    ['offdoctor'] = {
        ['Model'] = "A_M_M_BiVWorker_01",
        ['img'] = '/html/img/logo.png',
        ['Text'] = "จุดเข้า-ออกเวร: หมอ",
        ['coords'] = {x = -287.67, y = 801.84, z = 119.38, h = 184.61 },
        ['Distance'] = 1.5,
        ['Job'] = "doctor",
        ['offJob'] = "offdoctor",
    },
}

Config['PayCheckTime'] = 1 -- 1 = 1 นาที
Config['PayCheckReward'] = {
    ['police'] = {
        ['0'] = {
            moneytype = 'cash', 
            moneycount = 100,
            -- item = {
            --     bread = 1,
            --     water = 1,
            -- },
        },
        ['1'] = {
            moneytype = 'cash',
            moneycount = 150,
        },
    },
    ['doctor'] = {
        ['0'] = {
            moneytype = 'cash', 
            moneycount = 100,
        },
    },
}
