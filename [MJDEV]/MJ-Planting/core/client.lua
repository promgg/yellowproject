
-- ███╗░░░███╗░░░░░██╗██████╗░███████╗██╗░░░██╗
-- ████╗░████║░░░░░██║██╔══██╗██╔════╝██║░░░██║
-- ██╔████╔██║░░░░░██║██║░░██║█████╗░░╚██╗░██╔╝
-- ██║╚██╔╝██║██╗░░██║██║░░██║██╔══╝░░░╚████╔╝░
-- ██║░╚═╝░██║╚█████╔╝██████╔╝███████╗░░╚██╔╝░░
-- ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚══════╝░░░╚═╝░░░
-- Discord: https://discord.gg/gHRNMDQKzb 
-- Count/Start แยกตาม zoneId (แต่ละโซน/เมืองนับโควตาของตัวเอง ไม่ปนกัน)
-- เดิมเป็น scalar เดียวใช้ร่วมกันทุกโซนทั้งรีซอร์ส ทำให้ปลูกเต็มที่ Rhodes ไปบล็อกการปลูกที่ Valentine ด้วย
Count = {}
Start = {}
PLANT = {}
blips = {}
VORPcore = {}
ShowHelp = false
isPutfeed = false
isModelSwapping = false

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

-- ย้ายมาไว้ top-level (เดิมซ้อนอยู่ใน MJDEV_GetEvent_Planting ซึ่งสร้างฟังก์ชันนี้ก็ต่อเมื่อ
-- server ตอบกลับ round-trip ของ GetEvent_Planting เท่านั้น - ถ้ารีสตาร์ทรีซอร์สเร็วเกินไปก่อน
-- round-trip เสร็จ onResourceStop จะเรียกฟังก์ชันที่ยังไม่ถูกสร้าง เกิด error "attempt to call a nil value")
function RemoveAllBlips()
    for _, data in ipairs(blips) do
        RemoveBlip(data.blip)
        RemoveBlip(data.radius)
    end
    blips = {}
end

function LoadModel(model)
        local modelHash = GetHashKey(model)
        RequestModel(modelHash)

        local timeout = 5000 -- Timeout in milliseconds (5 seconds)
        local timer = GetGameTimer()

        while not HasModelLoaded(modelHash) do
            Citizen.Wait(100)
            if GetGameTimer() - timer > timeout then
                print("Failed to load model:", model)
                return false
            end
        end

        return true
end

-- ── บล็อกจนกว่า lp_progbar:Progress จะจบ (สำเร็จ/ถูกยกเลิก) แล้วคืนค่า cancelled ──
-- (StartPlantings/client_core.lua เขียนแบบ blocking call-then-return เดิม เก็บ contract
--  นี้ไว้เหมือนเดิม แค่เปลี่ยนตัวเล่น progress bar/anim ข้างในเป็น lp_progbar)
function runProgress(action)
    local done, cancelled = false, false
    exports.lp_progbar:Progress(action, function(c)
        cancelled = c
        done = true
    end)
    while not done do Citizen.Wait(0) end
    return cancelled
end

function animacion2()
    return runProgress({
        duration = 8000,
        label = 'Watering...',
        controlDisables = { disableMovement = true },
        animation = { task = 'WORLD_HUMAN_BUCKET_POUR_LOW' },
    })
end

-- ── Progress ตอนปลูก (ก่อนหักเมล็ด/spawn จริง) — ท่าปลูกเมล็ดลงดิน ──
-- ยกมาจาก Devchacha Farming ตรงๆ (FinalizePlacement: TaskStartScenarioInPlace WORLD_HUMAN_FARMER_WEEDING, 5000ms)
-- โปรเจกต์อ้างอิงไม่มีท่า "พลวนดิน" แยกต่างหาก — นี่คือท่าเดียวที่เล่นตอนปลูกเมล็ด
function animPlant()
    local isMale = IsPedMale(PlayerPedId())
    local anim = isMale
        and { task = 'WORLD_HUMAN_FARMER_WEEDING' }
        or  { animDict = "amb_work@world_human_farmer_weeding@male_a@idle_a", anim = "idle_a" }
    return runProgress({
        duration = 5000,
        label = 'กำลังปลูกเมล็ด...',
        controlDisables = { disableMovement = true },
        animation = anim,
    })
end

-- ใส่ปุ๋ย (ท่าหว่าน feed-chicken — หัก compost หลังจบ)
-- ใช้ animDict/anim ตรงๆ แทน task scenario (WORLD_HUMAN_FEED_CHICKEN เป็น scenario ที่ผูกกับ
-- prop/scenario-point ของเกม เรียกผ่าน TaskStartScenarioInPlace ตรงๆ แล้วไม่เล่นท่าให้เห็นจริงในเกม
-- — ตรวจพบจากการเทสจริง — animDict "world_human_feed_chickens" เป็นคลิปเดียวกัน เล่นตรงด้วย TaskPlayAnim ได้ชัวร์กว่า)
-- ท่านี้ไม่ผูก prop มากับ scenario เอง (ต่างจาก WATER ที่ใช้ WORLD_HUMAN_BUCKET_POUR_LOW) เลยไม่มีถุงปุ๋ยติดมือ
-- ให้เห็น — ใส่ prop ถุงปุ๋ย (p_feedbag01x) ติดมือซ้ายเองผ่าน lp_progbar prop field (ไม่มี compost prop จริง
-- ในระบบ item จึงยืมโมเดลถุงอาหารสัตว์ทั่วไปของเกมมาใช้แทน)
function animFertilize()
    local isMale = IsPedMale(PlayerPedId())
    local anim = isMale
        and { animDict = "amb_work@world_human_feed_chickens@male_a@idle_a", anim = "idle_a" }
        or  { animDict = "amb_work@world_human_feed_chickens@female_a@idle_a", anim = "idle_a" }
    return runProgress({
        duration = 6000,
        label = 'กำลังใส่ปุ๋ย...',
        controlDisables = { disableMovement = true },
        animation = anim,
        prop = {
            model = 'p_feedbag01x',
            bone = GetEntityBoneIndexByName(PlayerPedId(), 'SKEL_L_Hand'),
        },
    })
end

-- ── จุดปลูก: ตรงหน้าผู้เล่นระยะคงที่ คืน { coords, heading } ──
-- เดิมเป็น ghost placement (prop โปร่งใส + WASD/Q/Z เล็งเอง) ตัดออกแล้ว: ใช้เมล็ดปุ๊บลงต้นตรงหน้าเลย
-- ระยะ/ระยะห่างจากต้นอื่น server ตรวจซ้ำอยู่แล้วใน ConfirmPlace:SV จึงไม่เสียความปลอดภัย
--
-- z ที่คืนไปเป็นแค่ค่าประมาณจากระดับพื้น — ทั้งตอน spawn จริงและตอน restorePlant เรียก
-- PlaceObjectOnGroundProperly ต่ออยู่แล้ว ต้นจึงสแนปลงพื้นเองไม่ลอย/ไม่จม
function PlantSpotInFront(dist)
    local ped = PlayerPedId()
    local p   = GetEntityCoords(ped)
    local f   = GetEntityForwardVector(ped)
    local x, y = p.x + f.x * (dist or 1.5), p.y + f.y * (dist or 1.5)

    -- หาพื้นไม่เจอ (ยืนในน้ำ/ใต้สิ่งปลูกสร้าง) ใช้ z ของผู้เล่นแทน ดีกว่าได้ 0.0 แล้วต้นหลุดใต้แมพ
    local found, groundZ = GetGroundZFor_3dCoord(x, y, p.z + 1.0, false)
    local z = (found and groundZ) or p.z

    return { coords = vector3(x, y, z), heading = GetEntityHeading(ped) }
end

MJDEV_GetEvent_Planting = function()
    RegisterNetEvent("MJ-Planting:Start")
    AddEventHandler("MJ-Planting:Start", function(v)
        TriggerEvent("vorp_inventory:CloseInv")
        local playerCoords = GetEntityCoords(PlayerPedId())
        local isInZone = false

        if GetDistanceBetweenCoords(playerCoords, v.coords, true) < v.range then
            isInZone = true
        end

        if isInZone then
            StartPlantings(v)
        else
            MJDEV.NoZone(v)
        end
    end)

    Citizen.CreateThread(function()
        -- รวบยอด blip เป็นของ "โซน" (zoneId) แทนที่จะสร้างซ้อนทับกันทีละชนิดพืช — เดิมแต่ละเมืองมี 4 entries
        -- (Corn/Carrot/Yarrow/Sugarcane ฯลฯ) พิกัดเดียวกันเป๊ะ เลยได้ blip ซ้อนกัน 4 อันต่อโซน
        -- ตอนนี้เหลือ 1 blip ต่อ zoneId ป้ายเป็นชื่อโซนรวม (เช่น "Valentine Farm")
        -- ชื่อพืชแต่ละชนิด (blips.text เดิม เช่น "Valentine Farm - Corn") ยังอยู่ครบใน config เผื่อเอาไปโชว์แยกเป็น option ทีหลังได้
        local seenZones = {}
        for i = 1, #MJDEV['Planting'], 1 do
            local entry = MJDEV['Planting'][i]
            if entry.blips.enabled and not seenZones[entry.zoneId] then
                seenZones[entry.zoneId] = true

                local coord = entry.coords -- Coordinates for the blip
                local blip_modifier_hash = GetHashKey(entry.blips.color) -- Get the hash of the color for the blip
                local zoneLabel = entry.zoneName and (entry.zoneName .. ' Farm') or entry.blips.text

                -- Create the Blip at the defined coordinates
                local B = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coord.x, coord.y, coord.z)

                -- Create the radius for the blip
                local R = Citizen.InvokeNative(0x45F13B7E0A15C880, 693035517, coord.x, coord.y, coord.z, entry.range)

                -- Set Blip Sprite (Icon)
                SetBlipSprite(B, entry.blips.sprite)

                -- Set Blip Scale (Size)
                SetBlipScale(B, entry.blips.scale)

                -- Apply color if it's valid
                if blip_modifier_hash ~= 0 then
                    Citizen.InvokeNative(0x662D364ABF16DE2F, B, blip_modifier_hash)
                end

                -- Set the blip's text label (ชื่อโซนรวม ไม่ใช่ชื่อพืชแต่ละชนิด)
                Citizen.InvokeNative(0x9CB1A1623062F402, B, zoneLabel)

                -- Store the created blip and its radius in a table
                table.insert(blips, {
                    blip = B,
                    radius = R
                })
            end
        end
    end)
end

function BanditsStart()
        local banditmodel = GetHashKey('A_M_M_NEAROUGHTRAVELLERS_01')
        RequestModel(banditmodel)
        while not HasModelLoaded(banditmodel) do
            Citizen.Wait(100)
        end

        Citizen.Wait(100)
        local mat = math.random(2, 3)
        for i = 1, mat do
            local spread = 10.0
            local x_offset = math.random(-spread, spread)
            local y_offset = math.random(-spread, spread)
            local forwardoffset = GetOffsetFromEntityInWorldCoords(PlayerPedId(), x_offset, y_offset, 0.0)

            local npcs = CreatePed(banditmodel, forwardoffset.x, forwardoffset.y, forwardoffset.z, true, true, true, true)
            Citizen.InvokeNative(0x283978A15512B2FE, npcs, true)
            Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, npcs)

            local weapons = {"WEAPON_PISTOL", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_RIFLE"}
            local selectedWeapon = weapons[math.random(1, #weapons)]
            GiveWeaponToPed(npcs, GetHashKey(selectedWeapon), 50, true, true, 1, false, 0.5, 1.0, 1.0, true, 0, 0)
            SetCurrentPedWeapon(npcs, GetHashKey(selectedWeapon), true)

            TaskGoToEntity(npcs, PlayerPedId(), -1, 2.5, 4.0, 0, 0)
            Wait(500)
            TaskCombatPed(npcs, PlayerPedId())
            -- ตรวจสอบว่า NPC ตายแล้วหรือยัง
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(500) -- เช็คทุกครึ่งวินาที
                    if IsPedDeadOrDying(npcs, true) then
                        -- ลบ NPC ออกจากโลกทันทีเมื่อมันตาย
                        SetEntityAsNoLongerNeeded(npcs)
                        DeleteEntity(npcs)
                        break -- ออกจากลูปเมื่อ NPC ตาย
                    end
                end
            end)
            Wait(5000) -- ให้เวลา NPC สู้ประมาณ 5 วินาที (สามารถปรับตามต้องการ)
        end
    end

    function DrawText3D(x, y, z, text, type)
        local _type = type
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
        local px, py, pz = table.unpack(GetGameplayCamCoord())
        local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
        if onScreen then
            if _type == 0 then
                SetTextColor(163, 138, 184, 215)
            elseif _type == 1 then
                SetTextColor(117, 14, 14, 215)
            elseif _type == 2 then
                SetTextColor(255, 255, 255, 215)
            end
            SetTextScale(0.30, 0.30)
            SetTextFontForCurrentCommand(1)
            SetTextCentre(1)
            DisplayText(str, _x, _y - 0.13)
            local factor = (string.len(text)) / 225
            DrawSprite("feeds", "hud_menu_4a", _x, _y - 0.12, 0.015 + factor, 0.03, 0.1, 35, 35, 35, 190, 0)
        end
    end

    function DrawTexture(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11)
        if not HasStreamedTextureDictLoaded(textureStreamed) then
            RequestStreamedTextureDict(textureStreamed, false);
        else
            DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
        end
    end

    function DrawTexticon(x, y, z, a, b)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
        local px, py, pz = table.unpack(GetGameplayCamCoord())
        local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)

        if onScreen then
            if a ~= false then
                DrawTexture(a.iconDict, a.iconName, _x, _y - 0.25, 0.03, 0.05, 0.0, a.color.r, a.color.g, a.color.b,
                    a.color.a, true)
            end
            if b ~= false then
                DrawTexture(b.iconDict, b.iconName, _x, _y - 0.25, 0.03, 0.05, 0.0, b.color.r, b.color.g, b.color.b,
                    b.color.a, true)
            end
        end
    end

    function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
        local str = CreateVarString(10, "LITERAL_STRING", str, Citizen.ResultAsLong())
        SetTextScale(w, h)
        SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
        SetTextCentre(centre)
        if enableShadow then
            SetTextDropshadow(1, 0, 0, 0, 255)
        end
        Citizen.InvokeNative(0xADA9255D, fontId);
        DisplayText(str, x, y)
    end

    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            if PLANT ~= nil then
                for i = 1, #PLANT, 1 do
                    DeleteObject(PLANT[i].Planting)
                    DeleteEntity(PLANT[i].Planting)
                    SetEntityInvincible(PLANT[i].Planting, false)
                end
            end
            RemoveAllBlips()
            exports.lp_rewardpanel:Hide()
        end
    end)
