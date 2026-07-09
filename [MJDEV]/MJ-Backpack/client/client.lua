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
