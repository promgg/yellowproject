NX_GR = NX_GR or {}

local graveState = {}
local running = false
local activeGrave = nil
local busy = false

-- เรียกตอนเริ่ม/จบ dig session หรือ pray — ซ่อน lp_textui ระหว่าง lp_progbar/minigame ทำงาน
-- ไม่งั้นลูปข้างล่างจะเห็นหลุมเดิม (state เปลี่ยนเป็น pray ได้ระหว่างขุด) แล้วโชว์ prompt ทับซ้อนขึ้นมา
function NX_GR.SetInteractionBusy(v)
    busy = v
    if v and activeGrave then
        exports.lp_textui:CancelHold()
        activeGrave = nil
    end
end

local function isAvailable(graveId)
    local state = graveState[graveId]
    return not state or state.state == 'available'
end

-- หลุมแต่ละอันห่างกันมากกว่า interaction.distance เสมอ (คลัสเตอร์เว้น 8-12m, ระยะโต้ตอบ ~2m)
-- เลยไม่มีทางมีมากกว่า 1 หลุมเข้าระยะพร้อมกันจริง แต่ไล่หาที่ใกล้สุดไว้กันกรณีคอนฟิกเปลี่ยนในอนาคต
local function findNearestGraveAction()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearest, nearestDist, nearestAction, nearestLabel

    for _, grave in ipairs(Config.Graves) do
        if grave.enabled then
            local dist = #(playerCoords - grave.coords)
            local range = grave.interaction.distance or 2.0

            if dist <= range and (not nearestDist or dist < nearestDist) then
                if isAvailable(grave.id) then
                    nearest, nearestDist = grave, dist
                    nearestAction, nearestLabel = 'dig', NX_GR.Locale('dig_grave')
                elseif Config.Pray.enabled then
                    nearest, nearestDist = grave, dist
                    nearestAction, nearestLabel = 'pray', NX_GR.Locale('pray_grave')
                end
            end
        end
    end

    return nearest, nearestAction, nearestLabel
end

function NX_GR.ApplyGraveState(payload)
    if payload.graves then
        graveState = payload.graves
    elseif payload.graveId then
        graveState[payload.graveId] = payload
    end
end

function NX_GR.RegisterTargets()
    if running then return end
    running = true

    Citizen.CreateThread(function()
        while running do
            Citizen.Wait(activeGrave and 0 or 250)

            if busy then
                if activeGrave then
                    exports.lp_textui:CancelHold()
                    activeGrave = nil
                end
                goto continue
            end

            local grave, action, label = findNearestGraveAction()

            if activeGrave and grave ~= activeGrave then
                exports.lp_textui:CancelHold()
                activeGrave = nil
            end

            if grave and not activeGrave then
                activeGrave = grave
                local thisGrave, thisAction = grave, action
                if Config.Debug then
                    print(('[nx_graverobbery] hold start grave=%s action=%s dist_ok'):format(thisGrave.id, thisAction))
                end
                exports.lp_textui:TextUIHold(('[E] %s'):format(label), Config.Interaction.holdMs, function()
                    activeGrave = nil
                    if Config.Debug then
                        print(('[nx_graverobbery] hold complete grave=%s action=%s -> TriggerServerEvent'):format(thisGrave.id, thisAction))
                    end
                    if thisAction == 'dig' then
                        TriggerServerEvent('nx_graverobbery:server:requestStart', thisGrave.id)
                    else
                        TriggerServerEvent('nx_graverobbery:server:pray', thisGrave.id)
                    end
                end, nil, { coords = thisGrave.coords, offset = vector3(0.0, 0.0, 0.3) })
            end

            ::continue::
        end
    end)

    Citizen.CreateThread(function()
        while running do
            Citizen.Wait(2000)
            if Config.Debug then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local nearest, nearestDist
                for _, grave in ipairs(Config.Graves) do
                    local dist = #(playerCoords - grave.coords)
                    if not nearestDist or dist < nearestDist then
                        nearest, nearestDist = grave, dist
                    end
                end
                if nearest then
                    print(('[nx_graverobbery] debug nearest=%s dist=%.2f range=%.2f available=%s'):format(
                        nearest.id, nearestDist, nearest.interaction.distance or 2.0, tostring(isAvailable(nearest.id))
                    ))
                end
            end
        end
    end)
end

function NX_GR.RemoveTargets()
    running = false
    if activeGrave then
        exports.lp_textui:CancelHold()
        activeGrave = nil
    end
end
