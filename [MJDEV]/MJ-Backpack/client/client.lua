local VORPcore = exports.vorp_core:GetCore()
local BackpackInInventory = false
local BackpackAttached = false
local GetBackpackModel = nil
local Backpack = nil

if Config.Debug then
    Citizen.CreateThread(function()
        TriggerServerEvent('MJ-Backpack:server:CheckBackpack')
    end)
end

RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Citizen.Wait(10000)
    TriggerServerEvent('MJ-Backpack:server:CheckBackpack')
end)

RegisterNetEvent('MJ-Backpack:client:HasBackpack')
AddEventHandler('MJ-Backpack:client:HasBackpack', function(BackpackModel)
    BackpackInInventory = true
    GetBackpackModel = BackpackModel
end)

RegisterNetEvent('MJ-Backpack:client:HasNoBackpack')
AddEventHandler('MJ-Backpack:client:HasNoBackpack', function()
    BackpackInInventory = false
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Lowered wait time for quicker checks
        TriggerServerEvent('MJ-Backpack:server:CheckBackpack')

        if BackpackInInventory and not BackpackAttached and not IsPedOnMount(PlayerPedId()) then
            if GetBackpackModel then
                for _, backpack in ipairs(Config.Backpacks) do
                    if GetBackpackModel == backpack.Model then
                        LoadModel(backpack.Model)
                        Backpack = CreateObject(GetHashKey(backpack.Model), GetEntityCoords(PlayerPedId()), true, true, true)
                
                        if DoesEntityExist(Backpack) then
                            local Spine = GetEntityBoneIndexByName(PlayerPedId(), 'CP_Back')
                
                            AttachEntityToEntity(Backpack, PlayerPedId(), Spine, -0.35, 0.0, 0.12, -70.0, 0.0, -90.0, true, true, false, true, 1, true)
                
                            BackpackAttached = true
                            VORPcore.NotifyRightTip(GetPlayerServerId(PlayerId()), "🎒 คุณใส่กระเป๋าเรียบร้อยแล้ว!", 4000)
                            TriggerServerEvent('MJ-Backpack:server:LogBackpack', backpack.Model, true)
                        end
                    end
                end                
            end

        elseif not BackpackInInventory and BackpackAttached then
            if DoesEntityExist(Backpack) then
                BackpackAttached = false
                DetachEntity(Backpack, true, true)
                DeleteEntity(Backpack)
        
                VORPcore.NotifyRightTip(GetPlayerServerId(PlayerId()), "❌ คุณถอดกระเป๋าแล้ว!", 4000)
        
                -- 🔥 ส่งแจ้งเตือนไปที่ Server และ Discord
                TriggerServerEvent('MJ-Backpack:server:LogBackpack', GetBackpackModel, false)
            end
        end        

        Citizen.Wait(500)
    end
end)

-- ✅ โหลดโมเดล
function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
    end
end

-- ✅ ล้างข้อมูลเมื่อรีสตาร์ท
RegisterNetEvent('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if Backpack then
            DetachEntity(Backpack, true, true)
            DeleteEntity(Backpack)
        end
    end
end)

-- ===== คีย์ลัดเปิดกระเป๋า: กด Alt ค้าง + G =====
-- วิธีจับปุ่มยกมาจาก vorp_inventory/client/fastslot.lua (RegisterRawKeymap event-driven):
--   RegisterRawKeymap(name, onKeyDown, onKeyUp, vkCode, canBeDisabled)
-- ไม่แตะ control ของเกมเลย → Alt+G ไม่ชนปุ่มอื่น และเปิดได้ทุกเมื่อโดยไม่ต้องเปิดกระเป๋าไปกดไอเทม
-- server เป็นคนหาว่าผู้เล่นมีกระเป๋าใบไหนแล้วเปิดให้ (client แค่ยิง event เปล่า กัน spoof)
if Config.OpenKey and Config.OpenKey.enabled ~= false then
    local MOD_VK  = Config.OpenKey.modifierVK or 0x12 -- 0x12 = Alt
    local KEY_VK  = Config.OpenKey.keyVK or 0x47       -- 0x47 = G
    local modHeld = false
    local lastOpen = 0 -- cooldown กันสแปม (server ไม่มี cooldown เอง)

    local function setMod(state) modHeld = state end

    -- modifier: ดัก MENU (0x12) + เผื่อ build ที่ส่งเป็น LMENU(0xA4)/RMENU(0xA5) แยก
    RegisterRawKeymap('mjbackpack:mod', function() setMod(true) end, function() setMod(false) end, MOD_VK, true)
    if MOD_VK == 0x12 then
        RegisterRawKeymap('mjbackpack:modL', function() setMod(true) end, function() setMod(false) end, 0xA4, true)
        RegisterRawKeymap('mjbackpack:modR', function() setMod(true) end, function() setMod(false) end, 0xA5, true)
    end

    -- ปุ่มหลัก: ตอน "กดลง" ถ้า Alt ค้างอยู่ -> เปิดกระเป๋า
    RegisterRawKeymap('mjbackpack:open', function()
        -- fallback: เช็ค IsRawKeyDown เผื่อ event modifier พลาด (build บางตัวยิง up/down ไม่ครบ)
        local altDown = modHeld or IsRawKeyDown(MOD_VK) or IsRawKeyDown(0xA4) or IsRawKeyDown(0xA5)
        if not altDown then return end

        if IsPauseMenuActive() then return end
        if IsEntityDead(PlayerPedId()) then return end

        local now = GetGameTimer()
        if (now - lastOpen) < 600 then return end -- กันกดรัว
        lastOpen = now

        TriggerServerEvent('MJ-Backpack:server:OpenViaKey')
    end, function() end, KEY_VK, true)
end
