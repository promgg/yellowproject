Config = {}

Config.Language = "th"
Config.InteractHoldMs = 900 -- กดค้าง E กี่ ms ถึงเริ่ม action (prompt ลอย lp_textui)
Config.ShowDistance = 1.5
Config.PedSpawnDistance = 30.0
Config.ServerInteractionDistance = 5.0
Config.SessionTimeout = 60
Config.CountryName = "U.S.A"
Config.CardNumberPrefix = "FIXITFY-"

Config.Items = {
    male = "man_idcard",
    female = "woman_idcard",
}

Config.Prices = {
    create = 50,
    changePhoto = 25,
    replacement = 50,
}

Config.Image = {
    maxLength = 1024,
    allowEmpty = true,
}

Config.Commands = {
    delete = "deleteidcard",
    resetAll = "resetallidcards",
}

Config.AdminGroups = {
    admin = true,
    superadmin = true,
}

-- Config.DiscordWebhook/DiscordBotName ย้ายไป s/config_server.lua (server-only)
-- เพราะไฟล์นี้เป็น shared_script โหลดไปฝั่ง client ด้วย — ไม่ควรมี webhook URL หลุดไปให้ client เห็น

Config.Locale = {
    th = {
        promptTitle = "สำนักงานบัตรประจำตัว",
        interact = "ติดต่อเจ้าหน้าที่",
        noMoney = "เงินสดไม่เพียงพอ ค่าธรรมเนียม $${money}",
        invalidImage = "ลิงก์รูปไม่ถูกต้อง กรุณาใช้ URL แบบ https:// เท่านั้น",
        invalidSession = "รายการนี้หมดอายุ กรุณาติดต่อเจ้าหน้าที่อีกครั้ง",
        tooFar = "คุณอยู่ไกลจากเจ้าหน้าที่เกินไป",
        noCharacter = "ไม่พบข้อมูลตัวละคร",
        noCard = "ไม่พบข้อมูลบัตรใบนี้ หรือบัตรถูกยกเลิกแล้ว",
        alreadyCard = "ตัวละครนี้มีบัตรประจำตัวอยู่แล้ว",
        createSuccess = "ออกบัตรประจำตัวเรียบร้อยแล้ว",
        photoSuccess = "เปลี่ยนรูปประจำตัวเรียบร้อยแล้ว บัตรทุกใบถูกอัปเดต",
        sameImage = "รูปประจำตัวนี้เป็นรูปเดียวกับที่บันทึกอยู่",
        replacementSuccess = "ออกบัตรทดแทนเรียบร้อยแล้ว",
        stillHaveCard = "คุณยังมีบัตรเดิมอยู่ ไม่จำเป็นต้องออกบัตรทดแทน",
        inventoryFull = "ไม่สามารถเพิ่มบัตรลงกระเป๋าได้ กรุณาตรวจสอบพื้นที่ว่าง",
        serviceBusy = "ระบบกำลังดำเนินรายการ กรุณารอสักครู่",
        databaseError = "ระบบฐานข้อมูลขัดข้อง กรุณาลองใหม่ภายหลัง",
        cardDescription = "บัตรประจำตัวของ ${name}</br>หมายเลขประจำตัว: <span style=color:yellow;>${charid}</span>",
        noPermission = "คุณไม่มีสิทธิ์ใช้คำสั่งนี้",
        resetUsage = "ยืนยันด้วยคำสั่ง /${command} confirm",
        resetSuccess = "ล้างข้อมูลบัตรประจำตัวทั้งหมดแล้ว บัตรเก่าทุกใบถูกยกเลิก",
        deleteUsage = "วิธีใช้: /${command} [server id]",
        deleteSuccess = "ลบข้อมูลบัตรประจำตัวแล้ว",
    },
    en = {
        promptTitle = "Identity Office",
        interact = "Speak with the clerk",
        noMoney = "Not enough cash. Fee: $${money}",
        invalidImage = "Invalid image link. Only https:// URLs are accepted.",
        invalidSession = "This service session expired. Please speak with the clerk again.",
        tooFar = "You are too far away from the clerk.",
        noCharacter = "Character data was not found.",
        noCard = "This identity record does not exist or has been revoked.",
        alreadyCard = "This character already has an identity card.",
        createSuccess = "Identity card issued successfully.",
        photoSuccess = "Identity photo updated on every copy of the card.",
        sameImage = "This image is already saved on the identity record.",
        replacementSuccess = "Replacement identity card issued successfully.",
        stillHaveCard = "You still have your card. No need for a replacement.",
        inventoryFull = "The identity card could not be added to your inventory.",
        serviceBusy = "A service request is already being processed.",
        databaseError = "The identity database is unavailable. Please try again later.",
        cardDescription = "${name}'s identity card</br>Identity number: <span style=color:yellow;>${charid}</span>",
        noPermission = "You are not allowed to use this command.",
        resetUsage = "Confirm with /${command} confirm",
        resetSuccess = "All identity records were reset. Existing cards are now invalid.",
        deleteUsage = "Usage: /${command} [server id]",
        deleteSuccess = "Identity record deleted.",
    },
}

Config.IDCardNPC = {
    Valentine = {
        coords = vector4(-174.8076, 631.6697, 114.0888, 343.0915),
        models = "cs_brontesbutler",
        distance = 3.0,
        blips = {
            name = "IDENTITY OFFICE",
            sprite = -1656531561,
            scale = 0.6,
            modifier = "BLIP_MODIFIER_MP_COLOR_32",
        },
        anims = { dict = "WORLD_HUMAN_SMOKE_NERVOUS_STRESSED", name = false },
        timeSettings = { open = 8, close = 21, blipmodifier = "BLIP_MODIFIER_MP_COLOR_2" },
    },
    Rhodes = {
        coords = vector4(1226.9238, -1294.9279, 76.9057, 36.3926),
        models = "cs_brontesbutler",
        distance = 3.0,
        blips = {
            name = "IDENTITY OFFICE",
            sprite = -1656531561,
            scale = 0.6,
            modifier = "BLIP_MODIFIER_MP_COLOR_32",
        },
        anims = { dict = "WORLD_HUMAN_SMOKE_NERVOUS_STRESSED", name = false },
        timeSettings = { open = 8, close = 21, blipmodifier = "BLIP_MODIFIER_MP_COLOR_2" },
    },
    Annesburg = {
        coords = vector4(2932.9790, 1282.2402, 44.6529, 72.1896),
        models = "cs_brontesbutler",
        distance = 3.0,
        blips = {
            name = "IDENTITY OFFICE",
            sprite = -1656531561,
            scale = 0.6,
            modifier = "BLIP_MODIFIER_MP_COLOR_32",
        },
        anims = { dict = "WORLD_HUMAN_SMOKE_NERVOUS_STRESSED", name = false },
        timeSettings = { open = 8, close = 21, blipmodifier = "BLIP_MODIFIER_MP_COLOR_2" },
    },
}

Config.HideHud = function()
    if GetResourceState and GetResourceState("nx_hud") == "started" then
        pcall(function() exports["nx_hud"]:hideHud() end)
    end
end

Config.ShowHud = function()
    if GetResourceState and GetResourceState("nx_hud") == "started" then
        pcall(function() exports["nx_hud"]:showHud() end)
    end
end

function Notify(data)
    local text = data.text or "No message"
    local duration = data.time or 5000
    local notificationType = data.type or "info"
    if notificationType == "info" then notificationType = "information" end -- pNotify (noty) ใช้คำเต็ม ไม่ใช่ "info"
    local src = data.source

    if IsDuplicityVersion() then
        TriggerClientEvent("pNotify:SendNotification", src, { type = notificationType, text = text, timeout = duration })
    else
        exports.pNotify:SendNotification({ type = notificationType, text = text, timeout = duration })
    end
end

function Locale(key, substitutions)
    local language = Config.Locale[Config.Language] or Config.Locale.en
    local translation = language[key] or Config.Locale.en[key] or ("Missing locale: " .. key)

    for name, value in pairs(substitutions or {}) do
        local pattern = "%${" .. name .. "}"
        translation = translation:gsub(pattern, tostring(value):gsub("%%", "%%%%"))
    end

    return translation
end
