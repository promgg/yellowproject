local VORPcore = exports.vorp_core:GetCore()

local nearMailboard = false

local boardObjects = {} -- เก็บ Object ที่ถูกสร้างขึ้น
local objectModel = GetHashKey(Config.BoardModel) -- ใช้โมเดลจาก Config
-- โหลดและสร้าง Object เมื่อเริ่มเกม
Citizen.CreateThread(function()
    RequestModel(objectModel)
    while not HasModelLoaded(objectModel) do
        Citizen.Wait(10)
    end

    for _, loc in pairs(Config.BoardLocations) do
        local board = CreateObject(objectModel, loc.x, loc.y, loc.z - 1.0, false, false, true)
        SetEntityHeading(board, loc.heading)
        FreezeEntityPosition(board, true) -- ทำให้ Object ไม่ขยับ
        table.insert(boardObjects, board) -- บันทึก Object ไว้เพื่อลบตอนหยุดสคริปต์
    end
end)

local function openMailboard()
    exports.lp_textui:HideUI()
    -- รีเซ็ต ให้ลูปสร้าง prompt กดค้างใหม่หลังปิด UI ถ้ายังยืนอยู่ในระยะ
    -- (ไม่งั้น nearMailboard ค้างเป็น true แล้วไม่มีวงแหวนขึ้นอีกจนกว่าจะเดินออกไปแล้วกลับมา)
    nearMailboard = false
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "showUI", show = true })
    TriggerServerEvent("mailboard:getAll")
end

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local foundNear = false

        for _, loc in pairs(Config.BoardLocations) do
            local dist = #(playerCoords - vector3(loc.x, loc.y, loc.z))
            if dist < Config.InteractDistance then
                foundNear = true
                -- เรียก TextUIHold ครั้งเดียวตอนเข้าระยะ — export ตัวนี้ poll ปุ่ม E
                -- และขับวงแหวนเอง ยิง callback เมื่อกดค้างครบ (เหมือน lp_planting/lp_washing)
                if not nearMailboard then
                    exports.lp_textui:TextUIHold(
                        "เปิดกระดานจดหมาย",
                        Config.InteractHoldMs,
                        openMailboard,
                        nil, -- ปุ่ม default = E
                        { coords = vector3(loc.x, loc.y, loc.z - 0.5) }
                    )
                end
                break
            end
        end

        if nearMailboard and not foundNear then
            exports.lp_textui:HideUI()
        end
        nearMailboard = foundNear

        if nearMailboard then
            Citizen.Wait(200)
        else
            Citizen.Wait(1000)
        end
    end
end)

-- เปิด UI
RegisterCommand("openmail", function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "showUI", show = true })
    TriggerServerEvent("mailboard:getAll")
end)

-- ปิด UI
RegisterNUICallback("closeUI", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- สร้างโพสต์ใหม่
RegisterNUICallback("createPost", function(data, cb)
    local message = data.message or ""
    local imageURL = data.imageURL or ""

    TriggerServerEvent("mailboard:createPost", message, imageURL)

    -- รอเล็กน้อยแล้วโหลดโพสต์ใหม่
    Citizen.SetTimeout(500, function()
        TriggerServerEvent("mailboard:getAll")
    end)
    cb({ success = true })
end)

-- ดึงโพสต์ทั้งหมด (จาก UI)
RegisterNUICallback("getPosts", function(_, cb)
    TriggerServerEvent("mailboard:getAll")
    cb({})
end)

-- ลบโพสต์
RegisterNUICallback("deletePost", function(data, cb)
    local postId = data.postId
    if postId then
        TriggerServerEvent("mailboard:deletePost", postId)
        Citizen.SetTimeout(500, function()
            TriggerServerEvent("mailboard:getAll")
        end)
        cb({ success = true })
    else
        cb({ success = false, error = "ไม่มี ID ของโพสต์" })
    end
end)

-- รับโพสต์ทั้งหมดจากเซิร์ฟเวอร์
RegisterNetEvent("mailboard:receiveAll")
AddEventHandler("mailboard:receiveAll", function(posts, myIdentifier)
    SendNUIMessage({
        action = "loadMails",
        mails = posts,
        myIdentifier = myIdentifier,
        -- ส่งค่าจาก config ไปด้วยทุกครั้ง UI จะได้โชว์ราคา/วันหมดอายุตรงกับที่ server ใช้จริง
        -- (ถ้า hardcode ไว้ใน UI แล้วแก้ config ทีหลัง ตัวเลขจะไม่ตรงกันโดยไม่มีใครรู้)
        postPrice = Config.PostPrice or 0,
        expireDays = Config.PostExpireDays or 0
    })
end)

-- ปิด UI อัตโนมัติเมื่อ resource หยุด
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "showUI", show = false })
        exports.lp_textui:HideUI()
         for _, obj in pairs(boardObjects) do
            DeleteObject(obj)
        end
    end
end)
