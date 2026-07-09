local annoucement_queue = {}
local on = false

-- ฟังก์ชันเพื่อส่งคอนฟิกไปยัง NUI
function setupNUI()
    local maxQueue = 5 -- จำนวนสูงสุดในคิวที่ต้องการ
    SendNUIMessage({
        action = 'onSetupConfig',
        maximum = maxQueue
    })
end

RegisterNetEvent('JKL-annoucement_nui:true')
AddEventHandler('JKL-annoucement_nui:true', function()
    on = true
end)

RegisterNetEvent('JKL-annoucement_nui:false')
AddEventHandler('JKL-annoucement_nui:false', function()
    on = false
end)

RegisterNetEvent('JKL-annoucement_nui:annouce')
AddEventHandler('JKL-annoucement_nui:annouce', function(message)
    table.insert(annoucement_queue, message)

    -- เริ่มประกาศถ้าคิวมีข้อความและ NUI ปิดอยู่
    if #annoucement_queue == 1 and not on then
        pushAnnouncement()
    end
end)

function pushAnnouncement()
    if not on and #annoucement_queue > 0 then
        on = true
        local message = annoucement_queue[1]

        -- ตั้งค่าและส่งข้อความไปยัง NUI
        SendNUIMessage({
            action = 'onSetupConfig',
            maximum = #annoucement_queue
        })

        SendNUIMessage({
            action = 'onReceive',
            text = message,
            duration = Config.AnnouceTimer,
            pic = 'logo.png',
            color = '#ff0000' -- สีแดงตามธีมที่คุณต้องการ
        })

        -- รอจนกว่าการแสดงประกาศจะเสร็จ
        Citizen.SetTimeout(Config.AnnouceTimer, function()
            -- ลบข้อความที่แสดงผลในคิว
            table.remove(annoucement_queue, 1)
            on = false
            pushAnnouncement() -- เรียกใหม่ถ้ามีประกาศค้างในคิว
        end)
    end
end

-- Event สำหรับเพิ่มประกาศใหม่เข้าไปในคิว
RegisterNetEvent('JKL-Announcement:message')
AddEventHandler('JKL-Announcement:message', function(message)
    table.insert(annoucement_queue, message)
    pushAnnouncement()
end)
