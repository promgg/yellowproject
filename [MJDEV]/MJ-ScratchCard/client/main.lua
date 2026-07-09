-- client
local VORPcore = {}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

local reward = {}
local isClaiming = false

RegisterNetEvent("scratchTicket:showUI")
AddEventHandler("scratchTicket:showUI", function(rewardData)
    -- print("[DEBUG] Reward Data: ", json.encode(rewardData))
    if not rewardData or not rewardData.name then
        print("[ERROR] scratchTicket:showUI - rewardData ไม่ถูกต้อง")
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "SHOW_REWARD",
        imgPath = Config['imgPath'],
        reward = rewardData
    })

    -- เพิ่มเสียงแจ้งเตือนเมื่อ UI แสดงขึ้นมา
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)

RegisterNUICallback("claimReward", function(data, cb)
    if isClaiming then return cb("error") end -- ป้องกันกดรับซ้ำ
    isClaiming = true

    if not data.reward then
        print("[ERROR] claimReward - ไม่มี rewardData")
        cb("error")
        isClaiming = false
        return
    end
    
    reward = data.reward
    cb("ok")

    Citizen.SetTimeout(2000, function() isClaiming = false end) -- ป้องกันกดซ้ำภายใน 2 วินาที
end)


RegisterNUICallback("closeUI", function(data, cb)
    if reward.itemName then
        -- ✅ ให้ไอเทมแม้ว่าจะกด ESC ปิด UI
        TriggerServerEvent("scratchTicket:giveReward", reward)
        reward = nil -- รีเซ็ตค่าหลังจากให้รางวัล
    end

    SetNuiFocus(false, false) -- ปิด UI
    SendNUIMessage({ type = "hideUI" })
    cb("ok")
end)
