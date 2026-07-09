-- MJ-Planting NUI Monitor
-- ไม่แตะ client_core.lua — monitor PLANT[] แล้วส่ง NUI แยก

local nuiInZone = false

-- ── Helpers ──────────────────────────────────────
local function getZoneForCoords(coords)
    for i, zone in ipairs(MJDEV['Planting']) do
        if #(coords - zone.coords) <= zone.range then
            return i, zone
        end
    end
    return nil, nil
end

-- รูปแบบเดียวกับ lp_rewardpanel ที่ MJ-Lumberjack/MJ-Mining ใช้: { img, chance, item }
-- รวม giveitem จากทุก entry ที่ zoneId เดียวกัน (จุดเดียวกันปลูกได้หลายชนิดพืช
-- เดิมโชว์แค่ giveitem ของ entry แรกที่เจอ ทั้งที่ปลูกได้มากกว่านั้น)
local function buildRewardItems(zone)
    local items = {}
    for _, z in ipairs(MJDEV['Planting']) do
        if z.zoneId == zone.zoneId then
            for _, g in ipairs(z.giveitem) do
                table.insert(items, {
                    img    = 'nui://vorp_inventory/html/img/items/' .. g.item .. '.png',
                    chance = g.percent,
                    item   = g.item,
                })
            end
        end
    end
    return items
end

-- ── Per-plant floating panel loop (100ms) ────────
Citizen.CreateThread(function()
    Citizen.Wait(5000)
    local lastPos = {}  -- [id] = {x, y} dead-zone tracking
    local DEADZONE    = 3.0              -- pixels
    local LOD_SHOW    = MJDEV.LOD.show   -- m — max distance to show panel
    local LOD_FADE    = MJDEV.LOD.fade   -- m — distance where fade begins

    while true do
        Citizen.Wait(100)
        if not nuiInZone then goto continue end

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local panels = {}

        for i, v in ipairs(PLANT) do
            if v.Planting and DoesEntityExist(v.Planting) then
                local pc   = GetEntityCoords(v.Planting)
                local dist = #(coords - pc)
                if dist <= LOD_SHOW then
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(pc.x, pc.y, pc.z + 0.5)
                    if onScreen then
                        local id  = tostring(NetworkGetNetworkIdFromEntity(v.Planting))
                        local rawX = sx * 1920
                        local rawY = sy * 1080

                        -- Dead-zone: snap to last position if within threshold
                        local prev = lastPos[id]
                        if prev and math.abs(rawX - prev.x) < DEADZONE and math.abs(rawY - prev.y) < DEADZONE then
                            rawX = prev.x
                            rawY = prev.y
                        else
                            lastPos[id] = { x = rawX, y = rawY }
                        end

                        -- Scale & opacity
                        local scale   = math.max(0.5, math.min(1.0, 1.1 - dist / 14.0))
                        local opacity = dist <= LOD_FADE and 1.0
                            or math.max(0.0, 1.0 - (dist - LOD_FADE) / (LOD_SHOW - LOD_FADE))

                        local pct   = (v.PlantMax > 0) and math.floor((v.Hungry / v.PlantMax) * 100) or 0
                        local state = 'growing'
                        if v.Give then state = 'harvest'
                        elseif v.Feed then state = 'water' end

                        panels[#panels + 1] = {
                            id      = id,
                            x       = rawX,
                            y       = rawY,
                            scale   = scale,
                            opacity = opacity,
                            name    = v.Data.blips.text,
                            pct     = pct,
                            state   = state,
                            seedImg = 'nui://vorp_inventory/html/img/items/' .. v.Data.item.seed .. '.png',
                            feedImg = 'nui://vorp_inventory/html/img/items/' .. v.Data.item.feed .. '.png',
                        }
                    end
                else
                    -- Clean up dead-zone cache for out-of-range plants
                    local id = tostring(NetworkGetNetworkIdFromEntity(v.Planting))
                    lastPos[id] = nil
                end
            end
        end

        SendNUIMessage({ action = 'updatePlants', plants = panels })
        ::continue::
    end
end)

-- ── Zone reward preview (lp_rewardpanel) ──────────
-- ปลูกทำผ่านการใช้เมล็ด (usable item) โดยตรงแล้ว ไม่ต้องมี hint/กด E ในนี้
Citizen.CreateThread(function()
    Citizen.Wait(4000) -- รอ client_core init ก่อน

    while true do
        Citizen.Wait(250)

        local coords = GetEntityCoords(PlayerPedId())
        local zi, zone = getZoneForCoords(coords)

        if zone then
            if not nuiInZone then
                nuiInZone = true
                -- ใช้ zoneName (ชื่อเมือง) แทน blips.text ของ entry เดียว เพราะตอนนี้ panel
                -- รวมพืชทุกชนิดในโซนนี้แล้ว ใช้ชื่อพืชตัวเดียวเป็น title จะดูขัดกับ list ข้างล่าง
                exports.lp_rewardpanel:Show(buildRewardItems(zone), zone.zoneName or zone.blips.text, 'โอกาสได้ผลผลิต')
            end
        else
            if nuiInZone then
                nuiInZone = false
                exports.lp_rewardpanel:Hide()
            end
        end
    end
end)
