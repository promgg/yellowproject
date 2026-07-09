local VORPcore = exports.vorp_core:GetCore()
local Text3D = exports["MJ-Text3D"]:GetText3D()

local nearMailboard = false
-- จุดที่สามารถกดเปิด UI ได้
local mailboardLocations = {
    { x = -277.61, y = 804.44, z = 119.39 },
    { x = 1322.01, y = -1321.74, z = 77.89 },
    -- เพิ่มตำแหน่งอื่น ๆ ได้ตามต้องการ
}

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

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        -- nearMailboard = false

        for _, loc in pairs(Config.BoardLocations) do
            local dist = #(playerCoords - vector3(loc.x, loc.y, loc.z))
            if dist < Config.InteractDistance then
                nearMailboard = true
                if nearMailboard then
                    Text3D.AddWorldText("getAll", loc.x, loc.y, loc.z-0.5, "กด [E] เปิดกระดานจดหมาย!")
                end
                if IsControlJustPressed(0, 0xCEFD9220) then -- ปุ่ม E
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = "showUI", show = true })
                    TriggerServerEvent("mailboard:getAll")
                    nearMailboard = false
                end
                break
            end
        end

        if nearMailboard then
            Citizen.Wait(0)
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
        myIdentifier = myIdentifier
    })
end)

-- ปิด UI อัตโนมัติเมื่อ resource หยุด
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "showUI", show = false })
         for _, obj in pairs(boardObjects) do
            DeleteObject(obj)
        end
    end
end)
