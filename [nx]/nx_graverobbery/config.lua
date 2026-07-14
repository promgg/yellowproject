Config = {}

Config.Debug = false
Config.Locale = 'th'

Config.Interaction = {
    holdMs = 900, -- กดค้าง E กี่ ms ถึงเริ่ม action (prompt ลอย lp_textui)
}

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

-- ── lp_minigame:Circle() opts (ดู [LP]/lp_minigame/config.lua สำหรับ field ทั้งหมด) ──
Config.SkillCheck = {
    enabled = true,
    successNeeded = 3,
    failLimit = 1,
    difficulty = 5,
    duration = 4000,
    pool = { 'W', 'A', 'S', 'D' },
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
    -- ── แดนบน — 10 หลุมต่อเมือง เปิดขุดตามเวลา (ซ้ำทุกวัน) แทนคูลดาวน์นับถอยหลัง มีแจ้งเตือน sheriff/guard ──
    valentine = {
        label = 'Valentine',
        enabled = true,
        schedule = { enabled = true, openHour = 13, openMinute = 0 },
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
        schedule = { enabled = true, openHour = 14, openMinute = 0 },
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
        schedule = { enabled = true, openHour = 15, openMinute = 0 },
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

    -- ── แดนใต้ — คลัสเตอร์หลุมศพ ไม่มีแจ้งเตือน sheriff/guard เลย ──
    southern_territory = {
        label = 'แดนใต้',
        enabled = true,
        notification = {
            enabled = false,
            scope = 'same_village',
            recipientMode = 'jobs',
            roles = {},
            jobs = {},
            alertChance = 0,
            alertDelayMin = 0,
            alertDelayMax = 0,
            blipDuration = 0,
            routeEnabled = false,
        },
    },
}

-- ── ตัวสร้างคลัสเตอร์หลุมศพ — กระจาย N หลุมเป็นวงกลมรอบจุดยึด (anchor) เดียว
-- ใช้ทั้งแดนบน (10 หลุม/เมือง, เปิดตามเวลา, มีแจ้งเตือน) และแดนใต้ (10 หลุม/จุด, คูลดาวน์ 90 นาที, ไม่มีแจ้งเตือน) ──
local function buildGraveCluster(opts)
    local graves = {}
    for i = 1, opts.holeCount do
        -- หลุมที่ 1 อยู่ตรงพิกัด anchor เป๊ะ (ยืนที่จุดที่ให้มาแล้วต้องขุดได้เลย)
        -- หลุมที่เหลือค่อยกระจายเป็นวงกลมรอบๆ
        local offsetX, offsetY = 0.0, 0.0
        if i > 1 then
            local angle = math.rad((360.0 / (opts.holeCount - 1)) * (i - 2))
            offsetX = math.cos(angle) * opts.spreadRadius
            offsetY = math.sin(angle) * opts.spreadRadius
        end
        graves[#graves + 1] = {
            id = ('%s_hole_%02d'):format(opts.clusterId, i),
            villageId = opts.villageId,
            label = ('%s - หลุมที่ %d'):format(opts.labelPrefix, i),
            coords = vector3(
                opts.anchorCoords.x + offsetX,
                opts.anchorCoords.y + offsetY,
                opts.anchorCoords.z
            ),
            heading = opts.anchorHeading,
            target = { type = 'sphere' },
            interaction = { radius = 1.5, distance = 2.0 },
            enabled = true,
            robbery = {
                enabled = true,
                cooldownMinutes = opts.cooldownMinutes or 0, -- แดนบน = 0 (ตัวจริงคำนวณจาก schedule ตอน commit), แดนใต้ = 90
                requiredItem = 'tool_grave_shovel',
                requiredItemAmount = 1,
                consumeItem = false,
                damageDurability = false,
                durabilityLoss = 5,
            },
            notification = opts.notification,
            rewardPool = 'default_grave',
        }
    end
    return graves
end

Config.Graves = {}

-- ── แดนบน — 10 หลุม/เมือง เปิดขุดตามเวลาที่ตั้งไว้ใน Config.Villages[id].schedule (ซ้ำทุกวัน)
-- ไม่มีคูลดาวน์นับถอยหลังแบบแดนใต้ — หลุมที่ขุดแล้วจะปิดจนกว่าจะถึงรอบเปิดของพรุ่งนี้ ──
local northernAnchors = {
    { clusterId = 'valentine_grave', villageId = 'valentine', label = 'Valentine', coords = vector3(-104.2654, 259.4358, 103.5259), heading = 299.9986 },
    { clusterId = 'rhodes_grave', villageId = 'rhodes', label = 'Rhodes', coords = vector3(1728.1279, -431.4838, 48.6842), heading = 267.5973 },
    { clusterId = 'annesburg_grave', villageId = 'annesburg', label = 'Annesburg', coords = vector3(2889.3147, 487.5027, 66.5826), heading = 155.8634 },
}

for _, anchor in ipairs(northernAnchors) do
    for _, grave in ipairs(buildGraveCluster({
        clusterId = anchor.clusterId,
        villageId = anchor.villageId,
        labelPrefix = anchor.label,
        anchorCoords = anchor.coords,
        anchorHeading = anchor.heading,
        holeCount = 10,
        spreadRadius = 8.0,
        cooldownMinutes = 0,
        notification = { enabled = true, overrideVillageSettings = false },
    })) do
        table.insert(Config.Graves, grave)
    end
end

-- ── แดนใต้ — คลัสเตอร์หลุมศพ 3 จุด จุดละ 10 หลุม ไม่มีแจ้งเตือน sheriff/guard,
-- คูลดาวน์รายหลุม 90 นาที, มาก่อนขุดได้ก่อน (ใช้ระบบ reservation เดิม) ──
-- พิกัดจุดยึด (anchor) 3 จุด — ระยะกระจายหลุม 12m รอบจุดยึด (ปรับ spreadRadius ได้ถ้าจุดจริงต้องการระยะห่างอื่น)
local southernAnchors = {
    { id = 'southern_cluster_a', coords = vector3(-4442.2231, -2696.6106, -11.0692), heading = 349.2923 },
    { id = 'southern_cluster_b', coords = vector3(-5452.8638, -2911.2053, 0.7369), heading = 320.2536 },
    { id = 'southern_cluster_c', coords = vector3(-3334.7971, -2867.6985, -6.0935), heading = 172.5226 },
}

for _, anchor in ipairs(southernAnchors) do
    for _, grave in ipairs(buildGraveCluster({
        clusterId = anchor.id,
        villageId = 'southern_territory',
        labelPrefix = 'แดนใต้',
        anchorCoords = anchor.coords,
        anchorHeading = anchor.heading,
        holeCount = 10,
        spreadRadius = 12.0,
        cooldownMinutes = 90, -- 1.30 ชม
        notification = { enabled = false, overrideVillageSettings = false },
    })) do
        table.insert(Config.Graves, grave)
    end
end

function Config.CustomAlertRecipients(context)
    return {}
end

-- Config.Logging และ Config.RewardPools ย้ายไป server/config_server.lua (server-only)
-- เพราะ config.lua นี้เป็น shared_script โหลดไปฝั่ง client ด้วย — ไม่ควรมี webhook URL หรือ loot odds หลุดไปให้ client เห็น
