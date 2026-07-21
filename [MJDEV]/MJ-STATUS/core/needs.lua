PlayerStatus = {}
isdead = false
starve = false
notifstarve = false
notifthirst = false
notifstress = false
-- ให้ resource อื่น (เช่น MJ-Afk-Zone-ui ตอนเข้าโหมดพักผ่อน) หยุดการลด Hunger/Thirst ชั่วคราวได้
-- ผ่าน export ด้านล่างของไฟล์นี้ — ไม่กระทบ Stress/stamina/เลือดจากความหิว (จงใจ ไม่ได้ขอ)
local needsFrozen = false
-- ค่าที่ต้องลดต่อ 1 รอบ คำนวณจาก "กี่นาทีถึงหมด" ใน config
-- (เดิมบรรทัดนี้เป็น foodtime/thirsttime ที่อ่าน Config.HungerTickInterval มาแล้วไม่มีใครใช้ต่อ
--  ส่วนการลดจริง hardcode ไว้ที่ -10 ต่อรอบ ปรับ config เท่าไหร่ก็ไม่มีผล)
local function drainPerTick(maxValue, minutesToEmpty)
    local ticks = (minutesToEmpty * 60000) / Config.NeedsTickInterval
    if ticks <= 0 then return 0 end
    return maxValue / ticks
end

local HUNGER_DRAIN = drainPerTick(Config.MaxHunger, Config.HungerMinutesToEmpty)
local THIRST_DRAIN = drainPerTick(Config.MaxThirst, Config.ThirstMinutesToEmpty)
stresstime = Config.StressTickInterval 

RegisterNetEvent('vorp:PlayerForceRespawn', function(status)
    PlayerStatus["Thirst"] = Config.MaxHunger;
    PlayerStatus["Hunger"] = Config.MaxThirst;
    PlayerStatus["Stress"] = Config.MinStress;
end)

RegisterNetEvent('vorp:SelectedCharacter', function(charId)
    isLoggedIn = true
end)

RegisterNetEvent("MJ-STATUS:setStatus")
AddEventHandler("MJ-STATUS:setStatus", function(status)
    if type(status) ~= "string" or #status < 2 then
        return
    end

    local ok, decoded = pcall(json.decode, status)
    if not ok or type(decoded) ~= "table" then
        return
    end

    -- เติมคีย์ที่ขาดให้ครบเสมอ (server normalize มาให้แล้ว แต่กันไว้อีกชั้นเผื่อมี path อื่นยิงมา) —
    -- ค่า nil ตัวเดียวทำให้ทั้ง HUD thread พังทั้งเส้น
    decoded.Hunger = tonumber(decoded.Hunger) or Config.MaxHunger or 1000
    decoded.Thirst = tonumber(decoded.Thirst) or Config.MaxThirst or 1000
    decoded.Stress = tonumber(decoded.Stress) or Config.MinStress or 0

    isLoggedIn = true
    PlayerStatus = decoded
    if Config.Debug then
        print(('[MJ-STATUS] โหลดสถานะ: Hunger=%s Thirst=%s Stress=%s')
            :format(tostring(PlayerStatus.Hunger), tostring(PlayerStatus.Thirst), tostring(PlayerStatus.Stress)))
    end
end)

RegisterNetEvent("MJ-STATUS:getStatus")
AddEventHandler("MJ-STATUS:getStatus", function()
    TriggerServerEvent("MJ-STATUS:saveStatus", PlayerStatus)
end)

RegisterNetEvent("vorpmetabolism:changeValue")
AddEventHandler("vorpmetabolism:changeValue", function(a,b)
    if PlayerStatus and next(PlayerStatus) and isLoggedIn then
        if PlayerStatus.Hunger == a and PlayerStatus.Hunger > b then
            PlayerStatus.Hunger = b
        elseif PlayerStatus.Thirst == a and PlayerStatus.Thirst > b then
            PlayerStatus.Thirst = b
        elseif PlayerStatus.Stress == a and PlayerStatus.Stress < b then
            PlayerStatus.Stress = b
        end
    end
end)


CreateThread(function()
    while true do
        Wait(3000)

        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            local ped = PlayerPedId()

            --  ลดเลือดหากหิว ≤ 10%
            if PlayerStatus.Hunger <= (Config.MaxHunger * 0.01) then
                local newHealth = GetEntityHealth(ped) - 2  -- ลดเลือดทีละ 5
                if newHealth < 1 then
                    ApplyDamageToPed(ped, 500000, false, true, true)
                    SetEntityHealth(ped, 0)
                else
                    SetEntityHealth(ped, newHealth)
                end
            end

            --  ลดเลือดหากกระหาย ≤ 10%
            if PlayerStatus.Thirst <= (Config.MaxThirst * 0.01) then
                local newHealth = GetEntityHealth(ped) - 3  -- ลดเลือดทีละ 5
                if newHealth < 1 then
                    ApplyDamageToPed(ped, 500000, false, true, true)
                    SetEntityHealth(ped, 0)
                else
                    SetEntityHealth(ped, newHealth)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.NeedsTickInterval)
        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            local playerPed = PlayerPedId()
            local currentHealth = GetEntityHealth(playerPed)

            --  เช็ค & แจ้งเตือนความหิว
            -- print((Config.MaxHunger * 0.02))
            if PlayerStatus.Hunger <= (Config.MaxHunger * 0.02) and not notifstarve then
                -- ย้ายจาก MJ-Showitem (ปิดไปแล้ว) มาใช้ pNotify ระบบแจ้งเตือน text มาตรฐานของโปรเจกต์
                exports.pNotify:SendNotification({ type = 'error', text = '⚠ คุณกำลังหิวมาก! รีบหาอะไรกินด่วน!', timeout = 5000 })
                notifstarve = true
            else
                notifstarve = false
            end

            --  เช็ค & แจ้งเตือนความกระหายน้ำ
            if PlayerStatus.Thirst <= (Config.MaxThirst * 0.02) and not notifthirst then
                exports.pNotify:SendNotification({ type = 'error', text = '⚠ คุณกระหายน้ำมาก! รีบดื่มน้ำด่วน!', timeout = 5000 })
                notifthirst = true
            else
                notifthirst = false
            end

            --  ลดหลอด แล้วจำกัดไม่ให้เกิน Max / ต่ำกว่า 0
            -- floor ไว้เพราะค่าที่ลดต่อรอบอาจเป็นทศนิยม (เช่น 166.67) — ถ้าไม่ปัด สถานะจะถูก
            -- json.encode ลง DB เป็นทศนิยมยาวๆ อ่านไม่รู้เรื่องเวลาไปเปิดดูในตาราง characters
            -- ข้ามการลดทั้งคู่ถ้า needsFrozen (เช่นตอนพักผ่อนใน MJ-Afk-Zone-ui)
            if not needsFrozen then
                PlayerStatus.Hunger = math.max(math.min(math.floor(PlayerStatus.Hunger - HUNGER_DRAIN), Config.MaxHunger), 0)
                PlayerStatus.Thirst = math.max(math.min(math.floor(PlayerStatus.Thirst - THIRST_DRAIN), Config.MaxThirst), 0)
            end

            -- จำกัดค่า Hunger/Thirst ไม่ให้เกิน Max
            if PlayerStatus.Hunger > Config.MaxHunger then
                PlayerStatus.Hunger = Config.MaxHunger
            end

            if PlayerStatus.Thirst > Config.MaxThirst then
                PlayerStatus.Thirst = Config.MaxThirst
            end
        end
    end
end)


-- ── ลดสเตมิน่าตอนวิ่ง ───────────────────────────────────────────────────────
-- core ของ RDR3 เป็น 0-100 index 1 คือ stamina (index 0 คือ health)
-- ⚠️ RDR3 ผู้เล่นมี stamina "สองชั้น" คนละตัวกัน (เห็นชัดจาก MJ-Respwan:368-369):
--    inner core ring  = GetAttributeCoreValue(ped, 1)  -> ลดเมื่อ outer หมดแล้วเท่านั้น
--    outer stamina    = GetPlayerStamina(PlayerId())   -> ตัวที่ลดตอนวิ่งปกติ (ที่ HUD โชว์)
--
-- รอบแรกอ่าน core ring ผิดตัว มันคืน 0 ตลอดตอนวิ่งปกติ (ยังไม่แตะ core เลย)
-- ทำให้ระบบคิดว่าหมดแล้วตลอด ไม่เคย drain อะไรเลย — ต้องจับ outer แทน
--
-- อ่านด้วย GetPlayerStamina (ตัวเดียวกับที่ core/client.lua:84 ใช้โชว์ HUD)
-- ลดด้วย ChangePedStamina ซึ่งเป็น "delta" ไม่ใช่ set ค่าตรงๆ
-- (ยืนยันจาก vorp_core/spawnplayer.lua:164, MJ-Medic, MJ-Respwan, vorp_medic — ทุกที่ใช้แบบ delta)
local function getStamina()
    return GetPlayerStamina(PlayerId()) -- 0-100
end

-- บังคับ stamina ลงไปที่ target — เขียนเฉพาะตอนต้องลดจริง
-- ใช้ delta (target - current) จึงสู้กับ recharge ของ vorp_core ได้: ถ้ามันดันขึ้นเกิน target
-- รอบถัดไป current จะ > target แล้วเราลดกลับลงมา
local function drainStaminaTo(ped, target)
    local current = getStamina()
    if target < current then
        ChangePedStamina(ped, target - current) -- delta ลบ = ลด
        return current
    end
    return current
end

-- /statusdebug — ดูค่าปัจจุบันทั้งหมดในบรรทัดเดียว ใช้ตอนเทียบว่าหลอดบนจอตรงกับค่าจริงไหม
if Config.Debug then
    RegisterCommand('statusdebug', function()
        local ped = PlayerPedId()
        print(('[MJ-STATUS] ===== ค่าปัจจุบัน ====='))
        print(('  Hunger  %s / %s'):format(tostring(PlayerStatus and PlayerStatus.Hunger), tostring(Config.MaxHunger)))
        print(('  Thirst  %s / %s'):format(tostring(PlayerStatus and PlayerStatus.Thirst), tostring(Config.MaxThirst)))
        print(('  Stress  %s  (เริ่มหักเลือดที่ %d)'):format(tostring(PlayerStatus and PlayerStatus.Stress),
            math.floor((Config.MaxStress or 0) * 0.02)))
        print(('  stamina (outer)  %s / 100'):format(tostring(getStamina())))
        print(('  stamina core ring  %s'):format(tostring(GetAttributeCoreValue(ped, 1))))
        print(('  เลือด  %s'):format(tostring(GetEntityHealth(ped))))
    end, false)
end

CreateThread(function()
    if not (Config.Stamina and Config.Stamina.enabled) then return end

    local tick    = Config.Stamina.tickMs or 100
    local drainMs = (Config.Stamina.drainSeconds or 8.0) * 1000

    local startedAt    = nil -- เวลาที่เริ่มวิ่งรอบนี้
    local startedValue = nil   -- สเตมิน่าตอนเริ่มวิ่งรอบนี้
    local maxStamina   = 100.0 -- ค่าเต็มจริง จับจากค่าสูงสุดที่เคยเห็น (skill/perk ดันเกิน 100 ได้)

    while true do
        Wait(tick)

        if isLoggedIn then
            local ped = PlayerPedId()

            -- จับ "หลอดเต็มจริง" ตลอด ไม่ใช่แค่ตอนวิ่ง — เซิร์ฟนี้มี skill ดัน stamina เกิน 100
            -- (เห็นค่า 112 ใน log จริง) ถ้า hardcode 100 จะได้อัตราลดผิด วิ่ง 9 วิแทน 8
            local cur = getStamina()
            if cur > maxStamina then maxStamina = cur end

            local moving = Config.Stamina.sprintOnly
                and IsPedSprinting(ped)
                or (IsPedSprinting(ped) or IsPedRunning(ped))

            if moving and not IsPedDeadOrDying(ped, true) then
                if not startedAt then
                    startedAt    = GetGameTimer()
                    startedValue = cur
                    if Config.Debug then
                        print(('[MJ-STATUS] เริ่มวิ่ง — stamina เริ่มต้น %.1f (เต็ม %.0f)'):format(startedValue, maxStamina))
                    end
                end

                -- อัตราลดคิดจาก "หลอดเต็มจริง / drainSeconds" ไม่ใช่จาก 100 ตายตัว
                -- เต็ม 112 -> ลด 14/วิ -> วิ่งจากเต็มหมดใน 8 วิพอดี
                -- เริ่มครึ่งหลอด (56) -> หมดใน 4 วิ (ครึ่งเวลา ตามที่ตกลง)
                local elapsed = GetGameTimer() - startedAt
                local target  = startedValue - (elapsed / drainMs) * maxStamina
                if target < 0 then target = 0 end

                local before = drainStaminaTo(ped, target)

                if Config.Debug and (elapsed % 1000) < tick then
                    local after = getStamina()
                    print(('[MJ-STATUS] วิ่งมา %.1f วิ | สั่งเป็น %.1f | ก่อน %.1f | หลัง %.1f')
                        :format(elapsed / 1000, target, before, after))
                end
            else
                if Config.Debug and startedAt then
                    print(('[MJ-STATUS] หยุดวิ่ง — stamina เหลือ %.1f'):format(getStamina()))
                end
                startedAt    = nil
                startedValue = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)  -- ตรวจสอบทุก 1 วินาที
        if PlayerStatus and next(PlayerStatus)and isLoggedIn then
            -- ตรวจสอบสถานะการเคลื่อนไหว
            Wait(Config.StressTickInterval)
            local playerPed = PlayerPedId()
            local isRunning = IsPedRunning(playerPed)
            local isWalking = IsPedWalking(playerPed)

            -- เพิ่มความเครียดตามสถานะการเคลื่อนไหว
            if isRunning then
                -- ถ้าวิ่งเพิ่มความเครียด 20%
                PlayerStatus.Stress = PlayerStatus.Stress + 2
            elseif isWalking then
                -- ถ้าเดินเพิ่มความเครียด 10%
                PlayerStatus.Stress = PlayerStatus.Stress + 1
            end

            -- ตรวจสอบว่าเครียดเกิน 90 หรือไม่
            if PlayerStatus.Stress >= (Config.MaxStress * 0.02) and not isdead then
                exports.pNotify:SendNotification({ type = 'error', text = 'คุณรู้สึกเครียดมากเกินไป!!', timeout = 5000 })
                isdead = true  -- ตั้งค่า dead เป็น true เมื่อเครียดมากเกินไป
            end

            -- ตรวจสอบว่าเครียดถึง 100 หรือไม่
            if PlayerStatus.Stress >= (Config.MaxStress * 0.02) then
                if not notifstress then
                    exports.pNotify:SendNotification({ type = 'error', text = 'คุณเสียชีวิตจากความเครียด!!!', timeout = 5000 })
                    notifstress = true
                    local newHealth = GetEntityHealth(playerPed) - 20
                    if newHealth < 1 then
                        ApplyDamageToPed(playerPed, 500000, false, true, true)
                        SetEntityHealth(playerPed, 0)
                    end
                    SetEntityHealth(playerPed, newHealth)
                    isdead = true  -- ผู้เล่นตายแล้วตั้งค่า dead เป็น true
                end
            else
                -- ถ้าความเครียดลดลงไป, รีเซ็ตสถานะการแจ้งเตือนและการตาย
                PlayerStatus.Stress = PlayerStatus.Stress + 0.1
                notifstress = false
                if isdead then
                    -- รีเซ็ตสถานะการตายเมื่อความเครียดไม่ถึง 100
                    isdead = false
                end
            end
        end
    end
end)

-- Prevent hunger and thirst from exceeding limits
CreateThread(function()
    while true do
        Wait(5000)  -- Wait 5 seconds before checking again
        if PlayerStatus and next(PlayerStatus) and isLoggedIn then
            PlayerStatus.Hunger = math.min(PlayerStatus.Hunger, 100000)
            PlayerStatus.Thirst = math.min(PlayerStatus.Thirst, 100000)
            PlayerStatus.Stress = math.min(PlayerStatus.Stress, 100000)
        end
    end
end)

RegisterNetEvent("MJ-STATUS:useItem")
AddEventHandler("MJ-STATUS:useItem", function(index, hunger, thirst, stress, stamina, eatAnimDict, eatAnimName)
    local playerPed = PlayerPedId()
    local PlayerId = PlayerId()
    -- Retrieve the prop name from the Config based on itemType (bread, apple, etc.)
    local itemConfig = Config.FoodItems[index]
    if not itemConfig then
        -- ไม่ gate ด้วย Debug โดยตั้งใจ — นี่แปลว่ามีไอเทมกินได้ที่ยังไม่ได้ลงทะเบียนใน
        -- Config.FoodItems ผู้เล่นกินแล้วจะไม่มีผลอะไรเลย ต้องเห็นเสมอ
        print(('[MJ-STATUS] ^3ไอเทม "%s" ไม่มีใน Config.FoodItems^7 — กินแล้วไม่มีผล')
            :format(tostring(index)))
        return
    end
    
    local prop_name = itemConfig.prop_name  -- Get the prop name Config.FoodItems
    if (Config["FoodItems"][index]["Animation"] == "eat") then
        PlayAnimEat(prop_name)
    else
        PlayAnimDrink(prop_name)
    end

    if (Config["FoodItems"][index]["Effect"] ~= "") then
        ScreenEffect(Config["FoodItems"][index]["Effect"], Config["FoodItems"][index]["EffectDuration"])
    end

    local currentHunger = PlayerStatus.Hunger
    local currentThirst = PlayerStatus.Thirst
    local currentStress = PlayerStatus.Stress

    -- log เป็นขั้นๆ เพื่อให้รู้ว่าถ้าฟังก์ชันตาย มันตายตรงไหน
    -- ถ้าเห็น "จุดที่ 1" แล้วไม่เห็น "จุดที่ 2" = GetPlayerStamina พังจริง
    -- (แล้ว TriggerServerEvent ข้างล่างจะไม่ถูกยิง = กินแล้วไม่ถูกบันทึกลง DB)
    if Config.Debug then
        print(('[MJ-STATUS] จุดที่ 1 — กิน %s | +hunger=%s +thirst=%s +stress=%s +stamina=%s')
            :format(tostring(index), tostring(hunger), tostring(thirst), tostring(stress), tostring(stamina)))
    end

    local currentStamina = GetPlayerStamina(playerPed)

    if Config.Debug then
        print(('[MJ-STATUS] จุดที่ 2 — GetPlayerStamina คืน %s (ชนิด %s)')
            :format(tostring(currentStamina), type(currentStamina)))
    end

    -- Calculate new values after using the item
    local newHunger = math.min(Config.MaxHunger, currentHunger + hunger)
    local newThirst = math.min(Config.MaxThirst, currentThirst + thirst)
    local newStress = math.max(Config.MinStress, currentStress + stress)
    local newStamina = math.min(Config.MaxStamina, currentStamina + stamina)

    local status = {
        ['Hunger'] = newHunger,
        ['Thirst'] = newThirst,
        ['Stress'] = newStress
    }
    Citizen.InvokeNative(0xFECA17CF3343694B, PlayerId, newStamina)

    if Config.Debug then
        print(('[MJ-STATUS] จุดที่ 3 — กำลังส่งไปบันทึก: Hunger %s->%s Thirst %s->%s Stress %s->%s')
            :format(tostring(currentHunger), tostring(newHunger),
                    tostring(currentThirst), tostring(newThirst),
                    tostring(currentStress), tostring(newStress)))
    end

    TriggerServerEvent("MJ-STATUS:saveStatus", status)
end)

function ScreenEffect(effect, durationMinutes)
    local durationMilliseconds = durationMinutes * 60*1000 -- Convert minutes to milliseconds
    AnimpostfxPlay(effect)
    Citizen.Wait(durationMilliseconds)
    AnimpostfxStop(effect)
end

-- prop ต้องสร้าง "แล้วแปะเข้ามือทันทีในเฟรมเดียวกัน" ไม่งั้นมันจะลอยอยู่กลางอากาศที่พิกัดผู้เล่น
-- ระหว่าง Wait ก่อนแปะ (บั๊กเดิม: CreateObject ที่ z+0.2 → Wait(1000) → ค่อย Attach = prop ลอย 1 วิ)
-- แก้เป็น: เล่นท่าก่อน → รอให้มือยกขึ้น → ค่อยสร้าง+แปะ prop พร้อมกัน + โหลด/ลบโมเดลให้ครบ
local function spawnHeldProp(propName)
    local ped = PlayerPedId()
    local hashItem = GetHashKey(propName)
    if not IsModelValid(hashItem) then return nil end

    RequestModel(hashItem)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hashItem) and GetGameTimer() - t0 < 2000 do Wait(10) end
    if not HasModelLoaded(hashItem) then return nil end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hashItem, coords.x, coords.y, coords.z, true, true, false, false, true)
    SetEntityAsMissionEntity(prop, true, true)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Finger12")
    AttachEntityToEntity(prop, ped, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hashItem)
    return prop
end

local function removeHeldProp(prop)
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

function PlayAnimDrink(propName)
    local ped = PlayerPedId()
    local dict = "amb_rest_drunk@world_human_drinking@male_a@idle_a"
    local anim = "idle_a"

    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        Wait(50)
    end

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(800) -- ให้มือยกขึ้นก่อน ค่อยโผล่ prop (ไม่สร้างค้างไว้ให้ลอย)

    local prop = spawnHeldProp(propName)
    Wait(5200)

    removeHeldProp(prop)
    ClearPedSecondaryTask(ped)
end

function PlayAnimEat(propName)
    local ped = PlayerPedId()
    local dict = "mech_inventory@eating@multi_bite@wedge_a4-2_b0-75_w8_h9-4_eat_cheese"
    local anim = "quick_right_hand"

    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        Wait(50)
    end

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    Wait(800) -- ให้มือยกขึ้นก่อน ค่อยโผล่ prop (ไม่สร้างค้างไว้ให้ลอย)

    local prop = spawnHeldProp(propName)
    Wait(5200)

    removeHeldProp(prop)
    ClearPedSecondaryTask(ped)
end

-- Play an animation
function TaskAnim(animDict, animName, flags, duration)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
    end

    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 3.0, duration, flags, 0, 0, 0, 0)
    RemoveAnimDict(animDict)
end

-- ห้ามคืน nil เด็ดขาด — ผู้เรียกเอาไปหาร/เทียบค่าต่อทันที (เช่น client.lua เอาไป / 1000)
-- ถ้า PlayerStatus ยังไม่มาหรือขาดคีย์ (เช่นตัวละครเก่าที่ไม่มี Stress) จะพังทั้ง HUD thread
exports('setThirst', function() return tonumber(PlayerStatus.Thirst) or Config.MaxThirst or 1000 end)
exports('setHunger', function() return tonumber(PlayerStatus.Hunger) or Config.MaxHunger or 1000 end)
exports('setStress', function() return tonumber(PlayerStatus.Stress) or Config.MinStress or 0 end)
exports('setTemp', function() return temperature end)

------------------------------------------------
-- Export เพิ่มความเหนื่อยล้า
------------------------------------------------
exports("AddStress", function(amount)
    PlayerStatus.Stress = math.min(Config.MaxStress, PlayerStatus.Stress + amount)
end)

------------------------------------------------
-- Export หยุด/ปล่อยการลด Hunger/Thirst ชั่วคราว (เช่นตอนพักผ่อน)
------------------------------------------------
exports("SetNeedsFrozen", function(frozen)
    needsFrozen = frozen and true or false
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AnimpostfxStop("PlayerHealthPoor")
        AnimpostfxStop("MissionChoice")
        AnimpostfxStop("MP_MoonshinerDisorient")
        if PlayerStatus and not next(PlayerStatus) then
            Wait(2000)
            TriggerServerEvent("MJ-STATUS:loadStatus")
        end
    end
end)
