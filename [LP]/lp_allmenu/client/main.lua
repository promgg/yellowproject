local nuiOpen = false

local function openMenu()
  if nuiOpen then return end
  TriggerServerEvent('Allmenu:requestOpen')
end

RegisterNetEvent('Allmenu:open')
AddEventHandler('Allmenu:open', function(playerName, charId, avatarUrl)
  nuiOpen = true
  SetNuiFocus(true, true)

  local items = {}
  for _, item in ipairs(Config.Items) do
    table.insert(items, {
      id      = item.id,
      title   = item.title,
      desc    = item.desc,
      image   = item.image,
      enabled = item.action ~= nil,
    })
  end

  SendNUIMessage({
    type    = 'openMenu',
    name    = playerName,
    id      = charId,
    avatar  = avatarUrl,
    banners = Config.Banners,
    items   = items,
  })
end)

-- ปิด UI แล้ว run action — triggerMenu รับผิดชอบปิด NUI focus เอง ไม่ผ่าน closeMenu
RegisterNUICallback('triggerMenu', function(data, cb)
  cb('ok')
  nuiOpen = false
  SetNuiFocus(false, false)

  Citizen.Wait(100)

  for _, item in ipairs(Config.Items) do
    if item.id == data.menu then
      local action = item.action
      if not action then
        TriggerEvent('vorp:TipBottom', 'ระบบนี้ยังไม่เปิดให้บริการ', 3000)
        break
      end
      if action.type == 'command' then
        ExecuteCommand(action.name)
      elseif action.type == 'client_event' then
        local args = action.args or {}
        TriggerEvent(action.name, table.unpack(args))
      end
      break
    end
  end
end)

RegisterNUICallback('closeMenu', function(data, cb)
  cb('ok')
  nuiOpen = false
  SetNuiFocus(false, false)
end)

RegisterCommand(Config.Command, function()
  openMenu()
end, false)

-- ต้องใช้ Wait(0) เพราะ native นี้คือ JustPressed — return true แค่ 1 เฟรม
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if not nuiOpen and Citizen.InvokeNative(0x91AEF906BCA88877, 0, Config.DefaultKey) then
      openMenu()
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then
    SetNuiFocus(false, false)
  end
end)
