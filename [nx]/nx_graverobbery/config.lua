Config = {}

Config.Debug = false
Config.Locale = 'th'

Config.Security = {
    startDistanceTolerance = 3.0,
    completeDistanceTolerance = 4.0,
    maxRequestsPerMinute = 10,
    suspiciousRequestThreshold = 5,
    sessionExpireSeconds = 45,
    minimumDigDurationSeconds = 12,
    cleanupIntervalSeconds = 30,
    requirePlayerVillage = false,
    adminAce = 'nx_graverobbery.admin',
    adminGroups = { 'admin', 'superadmin' },
}

Config.Logging = {
    console = true,
    database = false,
    webhook = false,
    webhookUrl = '',
}

Config.AllowedTime = {
    enabled = false,
    startHour = 22,
    endHour = 5,
}

Config.Digging = {
    durationMs = 15000,
    shovelModel = 'p_shovel02x',
    animDict = 'amb_work@world_human_gravedig@working@male_b@base',
    animName = 'base',
    attachBone = 'SKEL_R_Hand',
    attachOffset = { x = 0.0, y = -0.19, z = -0.089 },
    attachRotation = { x = 274.19, y = 483.89, z = 378.40 },
}

Config.SkillCheck = {
    enabled = true,
    difficulty = { 'easy', 'easy', { areaSize = 60, speedMultiplier = 1 } },
    keys = { 'w', 'a', 's', 'd' },
}

Config.Pray = {
    enabled = true,
    cooldownSeconds = 10,
    durationMs = 8000,
    animations = {
        { dict = 'amb_misc@world_human_pray_rosary@base', name = 'base' },
        { dict = 'amb_misc@world_human_grave_mourning@kneel@female_a@idle_a', name = 'idle_a' },
        { dict = 'amb_misc@world_human_grave_mourning@male_b@idle_c', name = 'idle_g' },
    },
}

Config.Villages = {
    valentine = {
        label = 'Valentine',
        enabled = true,
        notification = {
            enabled = true,
            scope = 'same_village',
            recipientMode = 'jobs',
            roles = {},
            jobs = { 'sheriff', 'guard' },
            alertChance = 50,
            alertDelayMin = 3,
            alertDelayMax = 8,
            blipDuration = 60,
            routeEnabled = false,
        },
    },
    annesburg = {
        label = 'Annesburg',
        enabled = true,
        notification = {
            enabled = true,
            scope = 'same_village',
            recipientMode = 'jobs',
            roles = {},
            jobs = { 'sheriff', 'guard' },
            alertChance = 50,
            alertDelayMin = 3,
            alertDelayMax = 8,
            blipDuration = 60,
            routeEnabled = false,
        },
    },
    rhodes = {
        label = 'Rhodes',
        enabled = true,
        notification = {
            enabled = true,
            scope = 'same_village',
            recipientMode = 'jobs',
            roles = {},
            jobs = { 'sheriff', 'guard' },
            alertChance = 50,
            alertDelayMin = 3,
            alertDelayMax = 8,
            blipDuration = 60,
            routeEnabled = false,
        },
    },
}

Config.Graves = {
    {
        id = 'valentine_grave_001',
        villageId = 'valentine',
        label = 'Old Valentine Grave',
        coords = vector3(-238.62, 820.91, 123.76),
        heading = 0.0,
        target = { type = 'sphere' },
        interaction = { radius = 1.5, distance = 2.0 },
        enabled = true,
        robbery = {
            enabled = true,
            cooldownMinutes = 60,
            requiredItem = 'tool_grave_shovel',
            requiredItemAmount = 1,
            consumeItem = false,
            damageDurability = false,
            durabilityLoss = 5,
        },
        notification = { enabled = true, overrideVillageSettings = false },
        rewardPool = 'default_grave',
    },
    {
        id = 'annesburg_grave_001',
        villageId = 'annesburg',
        label = 'Old Annesburg Grave',
        coords = vector3(3014.37, 1452.94, 46.21),
        heading = 0.0,
        target = { type = 'sphere' },
        interaction = { radius = 1.5, distance = 2.0 },
        enabled = true,
        robbery = {
            enabled = true,
            cooldownMinutes = 60,
            requiredItem = 'tool_grave_shovel',
            requiredItemAmount = 1,
            consumeItem = false,
            damageDurability = false,
            durabilityLoss = 5,
        },
        notification = { enabled = true, overrideVillageSettings = false },
        rewardPool = 'default_grave',
    },
    {
        id = 'rhodes_grave_001',
        villageId = 'rhodes',
        label = 'Old Rhodes Grave',
        coords = vector3(1282.88, -1224.42, 80.85),
        heading = 0.0,
        target = { type = 'sphere' },
        interaction = { radius = 1.5, distance = 2.0 },
        enabled = true,
        robbery = {
            enabled = true,
            cooldownMinutes = 60,
            requiredItem = 'tool_grave_shovel',
            requiredItemAmount = 1,
            consumeItem = false,
            damageDurability = false,
            durabilityLoss = 5,
        },
        notification = { enabled = true, overrideVillageSettings = false },
        rewardPool = 'default_grave',
    },
}

Config.RewardPools = {
    default_grave = {
        emptyChance = 25,
        money = { enabled = true, min = 0, max = 10, currency = 0 },
        -- ไอเทมทั้งหมดยืนยันแล้วว่ามีจริงใน DB (mjdevcore_18k.items) — ตัวที่ไม่มีถูกแทนด้วย loot_ label ไทย
        items = {
            { name = 'loot_silver_coin', min = 1, max = 3, weight = 20 }, -- แทน coin_half_penny (ไม่มีใน DB) — เหรียญเงิน
            { name = 'cigar',            min = 1, max = 2, weight = 15 }, -- มีอยู่แล้วใน DB
            { name = 'loot_ring',        min = 1, max = 1, weight = 10 }, -- แทน silver_ring (ไม่มีใน DB) — แหวน
            { name = 'wedding_ring',     min = 1, max = 1, weight = 6  }, -- มีอยู่แล้วใน DB
            { name = 'loot_gold_tooth',  min = 1, max = 1, weight = 1  }, -- แทน gold_bar (ไม่มีใน DB) รางวัลหายาก — ฟันทอง
        },
    },
}

function Config.CustomAlertRecipients(context)
    return {}
end
