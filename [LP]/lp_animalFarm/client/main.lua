local currentZone = nil   -- zone ที่ UI กำลังเปิดอยู่
local zoneEntered = nil   -- zone ที่ player กำลังยืนอยู่ (ไม่จำเป็นต้องเปิด UI)
local nuiOpen     = false
local isDead      = false

local spawnedPeds = {}    -- [animalId] = pedHandle
local pedZone     = {}    -- [animalId] = zoneType ที่ spawn มา
local myPed       = PlayerPedId()   -- init ทันที กัน Thread 2 ได้ vector3(0,0,0)
local myPlayerId  = PlayerId()

-- ─── HINT (lp_textui, hold-to-open) + REWARD PREVIEW (lp_rewardpanel) ───────

local openUI -- forward-declared: showHint's TextUIHold callback needs it (defined further down)

local function buildRewardItems(zone)
  local items = {}
  for _, r in ipairs(zone.itemReward) do
    items[#items+1] = {
      img    = 'nui://vorp_inventory/html/img/items/' .. r.name .. '.png',
      chance = 100, -- ของรางวัลได้แน่นอนเมื่อครบ feedsRequired ไม่ใช่ % drop
      item   = r.name,
    }
  end
  return items
end

-- กดค้าง E (holdMs เท่ากับ MJ-Lumberjack/MJ-Mining/MJ-Planting) แทนกดครั้งเดียว
-- TextUIHold จัดการ control poll + progress ring ของตัวเอง เปิด UI ให้ผ่าน callback
local function showHint(zoneType)
  local zone = Config.Zones[zoneType]
  if not zone then return end
  exports.lp_textui:TextUIHold(('[E] ค้างเพื่อเปิด %s'):format(zone.nameTH), Config.holdMs, function()
    openUI(zoneType)
  end)
end

local function hideHint()
  exports.lp_textui:CancelHold()
end

local function showRewardPreview(zoneType)
  local zone = Config.Zones[zoneType]
  if not zone then return end
  exports.lp_rewardpanel:Show(buildRewardItems(zone), zone.nameTH)
end

local function hideRewardPreview()
  exports.lp_rewardpanel:Hide()
end

-- ─── HELPERS ─────────────────────────────────────────────────────────────────

local function isValidAnimalId(id)
  return type(id) == 'number' and id > 0 and math.floor(id) == id
end

local function sendNUI(data)
  SendNUIMessage(data)
end

-- ─── PED LIFECYCLE ───────────────────────────────────────────────────────────

local function spawnPed(animalId, zoneType)
  if spawnedPeds[animalId] then return end

  local zone = Config.Zones[zoneType]
  if not zone then return end

  local model = joaat(zone.pedModel)
  RequestModel(model)
  local t = 0
  while not HasModelLoaded(model) do
    Wait(100)
    t = t + 1
    if t >= 100 then   -- 10 วินาที
      print('[AnimalFarm] model load timeout: ' .. tostring(zone.pedModel))
      SetModelAsNoLongerNeeded(model)
      return
    end
  end

  local coords = zone.coords
  -- กระจาย ped รอบจุดศูนย์กลาง ใช้ animalId เป็น seed หมุนรอบวงกลม
  local angle  = (animalId * 72) * (math.pi / 180)   -- 72° ต่อตัว = 5 ตัวพอดีรอบ
  local radius = 2.5
  local ox = math.cos(angle) * radius + Config.pedOffset.x
  local oy = math.sin(angle) * radius + Config.pedOffset.y

  local ok, ped = pcall(CreatePed,
    model,
    coords.x + ox,
    coords.y + oy,
    coords.z + Config.pedOffset.z,
    coords.w,
    false, false, false, false
  )

  if not ok or not ped or ped == 0 then
    print('[AnimalFarm] CreatePed failed: ' .. tostring(zone.pedModel))
    SetModelAsNoLongerNeeded(model)
    return
  end

  local waitCount = 0
  repeat Wait(0); waitCount = waitCount + 1 until DoesEntityExist(ped) or waitCount >= 300
  if not DoesEntityExist(ped) then
    SetModelAsNoLongerNeeded(model)
    return
  end
  Citizen.InvokeNative(0x283978A15512B2FE, ped, true)  -- SetRandomOutfitVariation
  PlaceEntityOnGroundProperly(ped, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetEntityInvincible(ped, true)
  SetEntityCanBeDamaged(ped, false)
  SetBlockingOfNonTemporaryEvents(ped, true)
  TaskSetBlockingOfNonTemporaryEvents(ped, true)

  -- ย่อ/ขยายขนาดตัว (ไม่ตั้งใน config = ขนาดปกติ)
  -- RDR2 ไม่มีโมเดลสัตว์วัยเด็กเลยสักชนิด (ไม่มี calf/foal/cub ใน ped list) อยากได้ตัวเล็ก
  -- จึงต้องย่อโมเดลตัวเต็มวัยเอา — ตั้งหลัง PlaceEntityOnGroundProperly เพราะย่อแล้วความสูงเปลี่ยน
  if zone.pedScale then
    SetPedScale(ped, zone.pedScale + 0.0)
    PlaceEntityOnGroundProperly(ped, true) -- วางพื้นซ้ำตามขนาดใหม่ ไม่งั้นตัวเล็กจะลอยเหนือพื้น
  end

  -- วนเดินในโซน radius 8m
  local zc = Config.Zones[zoneType].coords
  TaskWanderInArea(ped, zc.x, zc.y, zc.z, 8.0, 2.0, 5.0)
  spawnedPeds[animalId] = ped
  SetModelAsNoLongerNeeded(model)
end

local function deletePed(animalId)
  local ped = spawnedPeds[animalId]
  if ped and DoesEntityExist(ped) then
    SetEntityAsMissionEntity(ped, false, true)
    DeleteEntity(ped)
  end
  spawnedPeds[animalId] = nil
end

local function deleteAllPeds()
  for animalId in pairs(spawnedPeds) do
    deletePed(animalId)
  end
end

-- ─── ZONE ENTER / EXIT ───────────────────────────────────────────────────────

local function onZoneEnter(zoneType)
  if zoneEntered == zoneType then return end
  zoneEntered = zoneType
  local zone = Config.Zones[zoneType]
  if zone then
    showHint(zoneType)             -- แสดง hint ครั้งเดียวตอนเข้าโซน
    showRewardPreview(zoneType)    -- โชว์ preview ของรางวัลคู่กับ hint
  end
  TriggerServerEvent('animalfarm:zoneEnter', zoneType)
end

local function onZoneExit()
  if not zoneEntered then return end
  hideHint()
  hideRewardPreview()
  for animalId, zone in pairs(pedZone) do
    if zone == zoneEntered then
      deletePed(animalId)
      pedZone[animalId] = nil
    end
  end
  zoneEntered = nil
end

-- ─── UI ──────────────────────────────────────────────────────────────────────

local function closeUI(reason)
  if not nuiOpen then return end
  nuiOpen     = false
  currentZone = nil
  SetNuiFocus(false, false)
  sendNUI({ action = 'closeAnimalFarm' })
  -- ยังอยู่ในโซน → แสดง hint + reward preview กลับมาอีกครั้ง
  if zoneEntered and not isDead then
    local zone = Config.Zones[zoneEntered]
    if zone then
      showHint(zoneEntered)
      showRewardPreview(zoneEntered)
    end
  end
end

function openUI(zoneType)
  if isDead then return end
  local zone = Config.Zones[zoneType]
  if not zone then return end

  hideHint()            -- ซ่อน hint เมื่อเปิด UI
  hideRewardPreview()   -- ซ่อน reward preview คู่กัน (dashboard เปิดแล้ว)
  nuiOpen     = true
  currentZone = zoneType
  SetNuiFocus(true, true)

  local feedItems, rewardItems = {}, {}
  for _, it in ipairs(zone.itemFeed)   do feedItems[#feedItems+1]     = { name = it.name, qty = it.qty } end
  for _, it in ipairs(zone.itemReward) do rewardItems[#rewardItems+1] = { name = it.name, qty = it.qty } end

  sendNUI({ action = 'openAnimalFarm', data = {
    zoneName    = zone.nameTH,
    feedItems   = feedItems,
    rewardItems = rewardItems,
    animals     = {},
    hpDecayTime = Config.hpDecayTime,
    feedWindow  = Config.feedWindow,
  }})

  -- peds spawn แล้วตั้งแต่ zoneEnter ไม่ต้อง spawn ซ้ำ
  TriggerServerEvent('animalfarm:getAnimals', zoneType)
end

-- ─── HP TICK ─────────────────────────────────────────────────────────────────

-- hpTickRefs[animalId] = { startMs=GetGameTimer(), startHp=hp }
-- os.time() ไม่มีใน RedM client → ใช้ GetGameTimer() แทน
local hpTickRefs = {}

-- ตั้ง/อัปเดต ref ของสัตว์ 1 ตัว (ใช้ตอน open, add, feed)
local function setHpRef(id, hp, deathTimer)
  hpTickRefs[id] = {
    startMs           = GetGameTimer(),
    startHp           = hp or 100,
    deathTimerAtStart = deathTimer or (Config.hpDecayTime + Config.feedWindow),
  }
end

local function startHpTick(animals)
  hpTickRefs = {}
  for _, a in ipairs(animals) do
    if a.state == 'feed' then
      setHpRef(a.id, a.hp or 0, a.deathTimer or 0)
    end
  end
end

-- ─── SINGLE HP/TIMER TICKER (client authoritative — เจ้าเดียว, app.js render อย่างเดียว) ──
CreateThread(function()
  while true do
    if nuiOpen and next(hpTickRefs) then
      local updates = {}
      for id, ref in pairs(hpTickRefs) do
        local elapsedSec = (GetGameTimer() - ref.startMs) / 1000
        local hp         = math.max(0, ref.startHp - math.floor((elapsedSec / Config.hpDecayTime) * 100))
        -- timer = เวลาจนกว่าจะหิว (HP → 0); deathTimer = เวลาจนกว่าจะตาย
        local timer      = math.max(0, (ref.startHp / 100) * Config.hpDecayTime - elapsedSec)
        local deathTimer = math.max(0, ref.deathTimerAtStart - elapsedSec)
        updates[#updates+1] = {
          id = id, hp = hp,
          timer = math.floor(timer), deathTimer = math.floor(deathTimer),
        }
      end
      if #updates > 0 then sendNUI({ action = 'updateHp', data = updates }) end
      Wait(1000)
    else
      Wait(500)
    end
  end
end)

-- ─── THREAD 1: DEATH WATCH (500ms) ───────────────────────────────────────────

CreateThread(function()
  while true do
    Wait(500)
    myPed      = PlayerPedId()
    myPlayerId = PlayerId()

    local dead = IsEntityDead(myPed) or IsPlayerDead(myPlayerId)

    if dead and not isDead then
      isDead = true
      if nuiOpen then closeUI('player died') end
      hideHint()
      if zoneEntered then onZoneExit() end
      if not Config.syncPed then deleteAllPeds() end

    elseif not dead and isDead then
      isDead = false
    end
  end
end)

-- ─── THREAD 2: ZONE DETECTION (dynamic wait) ─────────────────────────────────

CreateThread(function()
  while true do

    -- ── UI เปิด: เช็กว่าออกนอก zone ไหม ────────────────────────────
    if nuiOpen and currentZone then
      local zone   = Config.Zones[currentZone]
      local coords = GetEntityCoords(myPed)
      if #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) > Config.zoneRadius + 5.0 then
        closeUI('left zone')
        onZoneExit()
      end
      Wait(500)
      goto continue
    end

    if isDead then Wait(1000); goto continue end

    -- ── เช็กว่าอยู่ใน zone ไหน ──────────────────────────────────────
    do
      local coords  = GetEntityCoords(myPed)
      local found   = nil
      for zoneType, zone in pairs(Config.Zones) do
        if #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) <= Config.zoneRadius then
          found = zoneType
          break
        end
      end

      -- zone enter/exit transitions
      if found and found ~= zoneEntered then
        if zoneEntered then onZoneExit() end  -- ออกจากโซนเก่าก่อน
        onZoneEnter(found)
      elseif not found and zoneEntered then
        onZoneExit()
      end
    end

    if not zoneEntered then
      -- ── ไกลทุกโซน: sleep นาน ────────────────────────────────────
      Wait(2000)
      goto continue
    end

    -- ── อยู่ใน zone: แค่ตรวจ exit ทุก 500ms ──
    -- (การกดค้าง E เปิด UI เป็นหน้าที่ของ lp_textui:TextUIHold เอง ทั้ง control poll
    --  และ callback อยู่แล้ว — thread นี้ไม่ต้อง poll คีย์เองอีกต่อไป)
    do
      local zone = Config.Zones[zoneEntered]
      while zoneEntered and not nuiOpen and not isDead do
        Wait(500)
        do
          local coords = GetEntityCoords(myPed)
          if #(coords - vector3(zone.coords.x, zone.coords.y, zone.coords.z)) > Config.zoneRadius then
            onZoneExit()
            break
          end
        end
      end
    end

    ::continue::
  end
end)

-- ─── NUI CALLBACKS ───────────────────────────────────────────────────────────

RegisterNUICallback('requestAnimals', function(_, cb)
  if nuiOpen and currentZone then
    TriggerServerEvent('animalfarm:getAnimals', currentZone)
  end
  cb('ok')
end)

RegisterNUICallback('closeUI', function(_, cb)
  closeUI('player pressed close')
  cb('ok')
end)

RegisterNUICallback('addAnimal', function(_, cb)
  if nuiOpen and currentZone then
    TriggerServerEvent('animalfarm:addAnimal', currentZone)
  end
  cb('ok')
end)

RegisterNUICallback('feedAnimal', function(data, cb)
  cb('ok')
  if not (nuiOpen and currentZone and isValidAnimalId(data and data.animalId)) then return end
  TriggerServerEvent('animalfarm:feedAnimal', data.animalId, currentZone)
end)

RegisterNUICallback('receiveReward', function(data, cb)
  if nuiOpen and currentZone and isValidAnimalId(data and data.animalId) then
    TriggerServerEvent('animalfarm:receiveReward', data.animalId, currentZone)
  end
  cb('ok')
end)

-- ─── SERVER → CLIENT EVENTS ──────────────────────────────────────────────────

RegisterNetEvent('animalfarm:spawnZonePeds')
RegisterNetEvent('animalfarm:receiveAnimals')
RegisterNetEvent('animalfarm:animalAdded')
RegisterNetEvent('animalfarm:animalFed')
RegisterNetEvent('animalfarm:animalRemoved')
RegisterNetEvent('animalfarm:notify')
RegisterNetEvent('animalfarm:animalDied')
RegisterNetEvent('animalfarm:cleanupSyncedPeds')

-- zone enter response: spawn peds เท่านั้น ยังไม่เปิด UI
AddEventHandler('animalfarm:spawnZonePeds', function(zoneType, animals)
  for _, a in ipairs(animals) do
    local id = a.id
    pedZone[id] = zoneType
    CreateThread(function() spawnPed(id, zoneType) end)
  end
end)

-- UI open response: full data สำหรับ NUI cards
AddEventHandler('animalfarm:receiveAnimals', function(animals)
  if not nuiOpen or not currentZone then return end
  local zone      = Config.Zones[currentZone]
  local pedName   = zone and string.upper(zone.pedModel:gsub('a_c_', '')) or 'ANIMAL'
  local pedImage  = zone and zone.image or nil
  local nuiAnimals = {}

  for _, a in ipairs(animals) do
    nuiAnimals[#nuiAnimals+1] = {
      id       = a.id,
      name     = pedName,
      image    = pedImage,
      type     = 'WILD',
      stage    = tostring(a.exp) .. '%',
      hp       = a.hp or 0,
      exp      = a.exp or 0,
      state      = a.state,
      timer      = a.timer or 0,
      deathTimer = a.deathTimer or 0,
      last_fed   = a.last_fed or 0,
    }
    -- ped อาจ spawn แล้วจาก zoneEnter แต่ถ้ายังไม่มีก็ spawn ตอนนี้
    -- state 'dead' ไม่มีแล้ว (ตายปุ๊บลบทิ้งเลย) เหลือกัน 'receive' ที่รอกดรับของอย่างเดียว
    if a.state ~= 'receive' then
      local aid = a.id
      local cz  = currentZone
      pedZone[aid] = cz
      CreateThread(function() spawnPed(aid, cz) end)
    end
  end

  sendNUI({ action = 'updateAnimals', data = { animals = nuiAnimals } })
  startHpTick(animals)
end)

AddEventHandler('animalfarm:animalAdded', function(zoneType, animal)
  -- spawn ped ทันทีที่ add (ผู้เล่นอยู่ในโซนอยู่แล้ว)
  local aid = animal.id
  pedZone[aid] = zoneType
  CreateThread(function() spawnPed(aid, zoneType) end)

  -- เพิ่ง add → เริ่ม track HP (แม้ UI จะยังไม่เปิด ก็ตั้ง ref ไว้)
  setHpRef(animal.id, 100, Config.hpDecayTime + Config.feedWindow)

  if not nuiOpen then return end
  local zone    = Config.Zones[zoneType]
  local pedName = zone and string.upper(zone.pedModel:gsub('a_c_', '')) or 'ANIMAL'
  sendNUI({ action = 'addCard', data = {
    id       = animal.id,
    name     = pedName,
    image    = zone and zone.image or nil,
    type     = 'WILD',
    stage    = '0%',
    hp       = 100,
    exp      = 0,
    state    = 'feed',
    timer    = Config.hpDecayTime,
    last_fed = animal.last_fed,
  }})
end)

AddEventHandler('animalfarm:animalFed', function(animalId, data)
  -- อัปเดต ref ให้ tick คำนวณ HP/timer จากเวลาที่ให้อาหารล่าสุด
  if data.state == 'feed' then
    setHpRef(animalId, data.hp or 100, data.deathTimer or (Config.hpDecayTime + Config.feedWindow))
  else
    hpTickRefs[animalId] = nil   -- state เปลี่ยนเป็น receive → หยุด track HP
  end
  sendNUI({ action = 'updateCard', data = {
    id    = animalId,
    state = data.state,
    hp    = data.hp,
    exp   = data.exp,
    -- feed แล้ว HP กลับ 100 → reset countdown เป็น hpDecayTime เต็ม
    timer = data.state == 'feed' and Config.hpDecayTime or 0,
  }})
end)

AddEventHandler('animalfarm:animalRemoved', function(animalId)
  deletePed(animalId)
  pedZone[animalId]   = nil
  hpTickRefs[animalId] = nil
  sendNUI({ action = 'removeCard', data = { id = animalId } })
end)

AddEventHandler('animalfarm:notify', function(msg, msgType)
  exports.pNotify:SendNotification({
    type    = msgType or 'info',
    text    = msg,
    timeout = 4000,
  })
end)

AddEventHandler('animalfarm:animalDied', function(animalId)
  hpTickRefs[animalId] = nil   -- หยุด track HP/timer
  -- server ลบแถวไปแล้ว เอาการ์ดออกเลย (เดิม markDead ค้างการ์ดไว้พร้อมปุ่ม DELETE ให้กดเอง)
  sendNUI({ action = 'removeCard', data = { id = animalId } })

  local ped = spawnedPeds[animalId]
  if not ped or not DoesEntityExist(ped) then return end

  CreateThread(function()
    -- คืน task control ให้ ped เดินได้
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskSetBlockingOfNonTemporaryEvents(ped, false)
    ClearPedTasksImmediately(ped)

    -- คำนวณทิศออกห่างจากศูนย์กลาง zone
    local zone = pedZone[animalId] and Config.Zones[pedZone[animalId]]
    local pos = GetEntityCoords(ped)
    local tx, ty = pos.x, pos.y
    if zone then
      local zc = zone.coords
      local dx = pos.x - zc.x
      local dy = pos.y - zc.y
      local len = math.sqrt(dx*dx + dy*dy)
      if len > 0.1 then
        tx = pos.x + (dx / len) * 8.0
        ty = pos.y + (dy / len) * 8.0
      end
    end

    TaskGoStraightToCoord(ped, tx, ty, pos.z, 0.6, 4000, GetEntityHeading(ped), 0.1)
    Wait(3500)
    deletePed(animalId)
    pedZone[animalId] = nil -- แถวถูกลบถาวรแล้ว ไม่ต้องจำโซนไว้อีก (เดิมค้างไว้จน resource restart)
  end)
end)

AddEventHandler('animalfarm:cleanupSyncedPeds', function(droppedSrc)
  for animalId, ped in pairs(spawnedPeds) do
    if ped and DoesEntityExist(ped) and NetworkGetEntityOwner(ped) == droppedSrc then
      DeleteEntity(ped)
      spawnedPeds[animalId] = nil
      pedZone[animalId]     = nil
    end
  end
end)

-- ─── BLIPS ───────────────────────────────────────────────────────────────────

local zoneBlips = {}

local function createBlips()
  for zoneKey, zone in pairs(Config.Zones) do
    local b = zone.blip
    if not b then goto continue end
    local c = zone.coords
    local blip = N_0x554d9d53f696d002(1664425300, c.x, c.y, c.z)
    SetBlipSprite(blip, b.sprite or -1646261997, 1)
    SetBlipScale(blip, b.scale or 0.5)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, b.label or zoneKey)
    zoneBlips[zoneKey] = blip
    ::continue::
  end
end

local function removeBlips()
  for _, blip in pairs(zoneBlips) do
    if DoesBlipExist(blip) then RemoveBlip(blip) end
  end
  zoneBlips = {}
end

AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  createBlips()
end)

-- ─── CLEANUP ─────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  closeUI('resource stopped')
  -- lp_textui/lp_rewardpanel เป็นรีซอร์สแยก ไม่ได้หยุดไปพร้อมกับเรา
  -- ต้องสั่ง hide เองไม่งั้น hint/reward panel จะค้างจอถ้าผู้เล่นยืนอยู่ในโซนตอน stop
  hideHint()
  hideRewardPreview()
  deleteAllPeds()
  removeBlips()
end)

-- สร้าง blip ทันทีถ้า resource โหลดแล้ว
createBlips()
