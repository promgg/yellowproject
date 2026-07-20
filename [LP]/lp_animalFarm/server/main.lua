local Core = nil
TriggerEvent('getCore', function(c) Core = c end)

-- ─── RATE LIMIT ───────────────────────────────────────────────────────────────

local cooldowns = {}
local COOLDOWN  = {
  addAnimal     = 1000,
  feedAnimal    = 1000,
  receiveReward = 1000,
  getAnimals    = 1000,
  zoneEnter     = 3000,   -- กัน spam เข้า-ออกโซนซ้ำๆ
}

-- scopeId (animalId/zoneType) กันไม่ให้คูลดาวน์ของ action หนึ่งไปบล็อก action เดียวกัน
-- แต่คนละสัตว์/คนละโซน (เดิม key เป็นแค่ action เฉยๆ ทำให้ feed สัตว์ตัวนึงไปบล็อกการ feed
-- ตัวอื่นที่ยืนติดกันโดยไม่ตั้งใจ) — ไม่ใส่ scopeId ก็ยังทำงานแบบ global ได้เหมือนเดิม
local function checkCooldown(src, action, scopeId)
  local t = GetGameTimer()
  if not cooldowns[src] then cooldowns[src] = {} end
  local key = scopeId ~= nil and (action .. ':' .. tostring(scopeId)) or action
  local last = cooldowns[src][key] or 0
  if (t - last) < COOLDOWN[action] then return false end
  cooldowns[src][key] = t
  return true
end

AddEventHandler('playerDropped', function()
  local src = source
  cooldowns[src] = nil
  -- synced peds are network entities owned by the dropped client
  -- the game engine cleans them, but we broadcast to be safe
  if Config.syncPed then
    TriggerClientEvent('animalfarm:cleanupSyncedPeds', -1, src)
  end
end)

-- ─── HELPERS ─────────────────────────────────────────────────────────────────

local function now() return os.time() end

-- safe character lookup — returns char object or nil
local function getChar(src)
  local ok, user = pcall(function() return Core.getUser(src) end)
  if not ok or not user then return nil end
  return user.getUsedCharacter
end

-- safe character lookup — returns charId or nil
local function getCharId(src)
  local char = getChar(src)
  if not char then return nil end
  return char.charIdentifier
end

-- ── safe vorp_inventory wrappers (pcall guarded) ─────────────────────────────
-- vorp exports เป็น async ของ external resource — ถ้า export หาย/ยิง error
-- เราต้องไม่ปล่อยให้ crash หรือทำ state ค้าง

local function safeGetItemCount(src, itemName, cb)
  local ok = pcall(function()
    exports.vorp_inventory:getItem(src, itemName, function(item)
      local count = 0
      if item then
        if type(item.getCount) == 'function' then
          count = item:getCount()
        else
          count = item.count or item.amount or 0
        end
      end
      cb(count)
    end)
  end)
  if not ok then cb(nil) end   -- nil = error (แยกจาก 0 = ไม่มีของ)
end

local function safeCanCarry(src, itemName, qty, cb)
  local ok, res = pcall(function()
    return exports.vorp_inventory:canCarryItem(src, itemName, qty)
  end)
  if not ok then cb(nil) else cb(res) end
end

-- ── feedLock: กัน concurrent feed + auto-release กันค้างถาวร ───────────────────
local feedLock = {}   -- [animalId] = true ระหว่าง async
local FEED_LOCK_TTL = 5000  -- ms — ถ้า callback ไม่กลับใน 5s ปลดล็อกอัตโนมัติ

local function lockFeed(animalId)
  if feedLock[animalId] then return false end
  feedLock[animalId] = true
  SetTimeout(FEED_LOCK_TTL, function() feedLock[animalId] = nil end)
  return true
end

local function unlockFeed(animalId)
  feedLock[animalId] = nil
end

-- input validation
local function isValidZone(z)   return type(z) == 'string' and Config.Zones[z] ~= nil end
local function isValidId(id)    return type(id) == 'number' and id > 0 and math.floor(id) == id end

-- server-side proximity check
local function isNearZone(src, zoneType)
  local zone = Config.Zones[zoneType]
  if not zone then return false end
  local ok, ped = pcall(GetPlayerPed, src)
  if not ok or not ped then return false end
  local coords = GetEntityCoords(ped)
  local zc     = zone.coords
  return #(coords - vector3(zc.x, zc.y, zc.z)) <= (Config.zoneRadius + 10.0) -- +10 buffer for lag
end

local function notify(src, msg, t) TriggerClientEvent('animalfarm:notify', src, msg, t or 'error') end

-- ─── LOAD ANIMALS ────────────────────────────────────────────────────────────

RegisterServerEvent('animalfarm:getAnimals')
AddEventHandler('animalfarm:getAnimals', function(zoneType)
  if not isValidZone(zoneType) then return end
  if not checkCooldown(source, 'getAnimals', zoneType) then
    notify(source, 'กำลังโหลดข้อมูลสัตว์ กรุณารอสักครู่', 'info')
    return
  end

  local src    = source
  local charId = getCharId(src)
  if not charId then return end

  MySQL.query(
    'SELECT id, slot, state, hp, exp, last_fed FROM animal_farm WHERE char_id = @cid AND zone_type = @zone ORDER BY slot ASC',
    { cid = charId, zone = zoneType },
    function(rows)
      if not rows then rows = {} end
      local updated = {}
      local deadIds = {}
      for _, row in ipairs(rows) do
        local died = false
        if row.state == 'feed' and row.last_fed and row.last_fed > 0 then
          local deadline = row.last_fed + Config.hpDecayTime + Config.feedWindow
          if deadline < now() then
            deadIds[#deadIds+1] = row.id
            died = true
          else
            local elapsed = now() - row.last_fed
            row.hp         = math.max(0, 100 - math.floor((elapsed / Config.hpDecayTime) * 100))
            row.timer      = math.max(0, (row.last_fed + Config.hpDecayTime) - now())
            row.deathTimer = math.max(0, deadline - now())
          end
        end
        -- ตายแล้วไม่ส่งกลับไปให้ NUI อีก การ์ดจะได้ไม่ค้างรอให้กดลบ
        if not died then table.insert(updated, row) end
      end

      -- ตัวที่ตายระหว่างผู้เล่นออฟไลน์ (decay tick วิ่งเฉพาะคนที่ออนไลน์) มาเก็บกวาดตอนเปิด UI
      if #deadIds > 0 then
        MySQL.update('DELETE FROM animal_farm WHERE id IN (' .. table.concat(deadIds, ',') .. ')')
        notify(src, ('สัตว์ของคุณตายไป %d ตัว (ไม่ได้ให้อาหารทันเวลา)'):format(#deadIds), 'error')
        for _, id in ipairs(deadIds) do
          TriggerClientEvent('animalfarm:animalDied', src, id)
        end
      end

      TriggerClientEvent('animalfarm:receiveAnimals', src, updated)
    end
  )
end)

-- ─── ZONE ENTER (lightweight — spawn peds only, no HP/EXP needed) ────────────

RegisterServerEvent('animalfarm:zoneEnter')
AddEventHandler('animalfarm:zoneEnter', function(zoneType)
  if not isValidZone(zoneType) then return end
  if not checkCooldown(source, 'zoneEnter', zoneType) then return end   -- ไม่ notify: trigger อัตโนมัติตอนเดินเข้าโซน ไม่ใช่การกดของผู้เล่น

  local src = source
  if not isNearZone(src, zoneType) then return end   -- gate ให้สอดคล้อง event อื่น

  local charId = getCharId(src)
  if not charId then return end

  MySQL.query(
    -- ไม่ต้องกรอง state != "dead" แล้ว: ตายปุ๊บแถวถูกลบทิ้งทันที ไม่มีสถานะนี้ค้างใน DB อีก
    'SELECT id, state FROM animal_farm WHERE char_id = @cid AND zone_type = @zone',
    { cid = charId, zone = zoneType },
    function(rows)
      if not rows or #rows == 0 then return end
      TriggerClientEvent('animalfarm:spawnZonePeds', src, zoneType, rows)
    end
  )
end)

-- ─── ADD ANIMAL ──────────────────────────────────────────────────────────────

RegisterServerEvent('animalfarm:addAnimal')
AddEventHandler('animalfarm:addAnimal', function(zoneType)
  local src = source
  if not isValidZone(zoneType) then return end
  if not checkCooldown(src, 'addAnimal', zoneType) then
    notify(src, 'กรุณารอสักครู่ก่อนซื้อสัตว์ตัวใหม่ในโซนนี้อีกครั้ง')
    return
  end

  if not isNearZone(src, zoneType) then
    notify(src, 'You are not near the zone')
    return
  end

  local char = getChar(src)
  if not char then notify(src, 'Character not found'); return end
  local charId = char.charIdentifier

  -- เช็คเงินก่อน (fail fast) — หักจริงหลังยืนยันว่ามี slot ว่าง
  local price = Config.addPrice or 0
  if price > 0 and (char.money or 0) < price then
    notify(src, ('เงินไม่พอ (ต้องใช้ $%d)'):format(price))
    return
  end

  local zone = Config.Zones[zoneType]

  -- step 1: count + find free slot (แยก query กัน oxmysql named-param ซ้ำ)
  MySQL.query(
    'SELECT COUNT(*) as cnt FROM animal_farm WHERE char_id=@cid AND zone_type=@zone',
    { cid = charId, zone = zoneType },
    function(rows)
      local cnt = (rows and rows[1] and rows[1].cnt) or 0
      if cnt >= zone.maxSlots then
        notify(src, 'Animal slots full (' .. zone.maxSlots .. ' max)')
        return
      end

      -- step 2: find free slot
      MySQL.query(
        'SELECT MIN(t.slot) as slot FROM (SELECT 1 AS slot UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t WHERE t.slot NOT IN (SELECT slot FROM animal_farm WHERE char_id=@cid AND zone_type=@zone)',
        { cid = charId, zone = zoneType },
        function(slotRows)
          local slot = slotRows and slotRows[1] and slotRows[1].slot
          if not slot then
            notify(src, 'No free slot available')
            return
          end

          -- step 3: หักเงิน (ตรวจซ้ำกัน race เงินหมดระหว่าง async) แล้วค่อย insert
          if price > 0 then
            if (char.money or 0) < price then
              notify(src, ('เงินไม่พอ (ต้องใช้ $%d)'):format(price))
              return
            end
            local okPay = pcall(function() char.removeCurrency(Config.moneyType, price) end)
            if not okPay then
              notify(src, 'ชำระเงินไม่สำเร็จ ลองใหม่')
              return
            end
          end

          -- step 4: insert (คืนเงินถ้า insert fail)
          MySQL.insert(
            'INSERT INTO animal_farm (char_id, zone_type, slot, state, hp, exp, last_fed) VALUES (@cid, @zone, @slot, "feed", 100, 0, @fed)',
            { cid = charId, zone = zoneType, slot = slot, fed = now() },
            function(id)
              if not id or id == 0 then
                if price > 0 then pcall(function() char.addCurrency(Config.moneyType, price) end) end
                notify(src, 'Failed to add animal, please try again')
                return
              end
              TriggerClientEvent('animalfarm:animalAdded', src, zoneType, {
                id = id, slot = slot, state = 'feed', hp = 100, exp = 0, last_fed = now()
              })
            end
          )
        end
      )
    end
  )
end)

-- ─── FEED ANIMAL ─────────────────────────────────────────────────────────────
-- feedLock / lockFeed / unlockFeed ประกาศไว้ที่ HELPERS (มี auto-release กันค้าง)

RegisterServerEvent('animalfarm:feedAnimal')
AddEventHandler('animalfarm:feedAnimal', function(animalId, zoneType)
  if not isValidId(animalId) or not isValidZone(zoneType) then return end
  if not checkCooldown(source, 'feedAnimal', animalId) then
    notify(source, 'กรุณารอสักครู่ก่อนให้อาหารตัวนี้ซ้ำ')
    return
  end
  if not lockFeed(animalId) then return end

  local src = source
  if not isNearZone(src, zoneType) then
    unlockFeed(animalId)
    notify(src, 'You are not near the zone')
    return
  end

  local charId = getCharId(src)
  if not charId then unlockFeed(animalId); notify(src, 'Character not found'); return end

  local zone = Config.Zones[zoneType]

  MySQL.query(
    'SELECT id, exp, state, last_fed FROM animal_farm WHERE id=@id AND char_id=@cid AND zone_type=@zone LIMIT 1',
    { id = animalId, cid = charId, zone = zoneType },
    function(rows)
      if not rows or #rows == 0 then
        unlockFeed(animalId)
        notify(src, 'Animal not found')
        return
      end
      local animal = rows[1]
      if animal.state ~= 'feed' then
        unlockFeed(animalId)
        notify(src, 'Animal is not ready to feed (state: ' .. tostring(animal.state) .. ')')
        return
      end

      local hungerTime = (animal.last_fed or 0) + Config.hpDecayTime
      local timeNow = now()
      if timeNow < hungerTime then
        unlockFeed(animalId)
        local remaining = hungerTime - timeNow
        local m = math.floor(remaining / 60)
        local s = remaining % 60
        notify(src, 'Animal is not hungry yet (' .. m .. 'm ' .. s .. 's remaining)')
        return
      end

      local feedItem = zone.itemFeed[1]
      safeGetItemCount(src, feedItem.name, function(itemCount)
        if itemCount == nil then
          unlockFeed(animalId)
          notify(src, 'ตรวจสอบไอเทมไม่สำเร็จ ลองใหม่')
          return
        end
        if itemCount < feedItem.qty then
          unlockFeed(animalId)
          notify(src, 'Not enough ' .. feedItem.name .. ' (need ' .. feedItem.qty .. ', have ' .. itemCount .. ')')
          return
        end

        local okSub = pcall(function()
          exports.vorp_inventory:subItem(src, feedItem.name, feedItem.qty, nil, function(ok)
            if not ok then
              unlockFeed(animalId)
              notify(src, 'Failed to deduct item, please try again')
              return
            end

            local expGain  = math.floor(100 / zone.feedsRequired)
            local newExp   = math.min(100, animal.exp + expGain)
            local newState = newExp >= 100 and 'receive' or 'feed'

            MySQL.update(
              'UPDATE animal_farm SET state=@s, hp=100, exp=@exp, last_fed=@fed WHERE id=@id AND char_id=@cid',
              { s = newState, exp = newExp, fed = now(), id = animalId, cid = charId },
              function(affected)
                unlockFeed(animalId)
                if not affected or affected == 0 then return end
                TriggerClientEvent('animalfarm:animalFed', src, animalId, {
                  state      = newState,
                  hp         = 100,
                  exp        = newExp,
                  -- เพิ่งให้อาหาร → นับใหม่: หิวอีกครั้งใน hpDecayTime, ตายใน hpDecayTime+feedWindow
                  deathTimer = newState == 'feed' and (Config.hpDecayTime + Config.feedWindow) or 0,
                })
              end
            )
          end)
        end)
        if not okSub then
          unlockFeed(animalId)
          notify(src, 'Failed to deduct item, please try again')
        end
      end)
    end
  )
end)

-- ─── RECEIVE REWARD ──────────────────────────────────────────────────────────

RegisterServerEvent('animalfarm:receiveReward')
AddEventHandler('animalfarm:receiveReward', function(animalId, zoneType)
  if not isValidId(animalId) or not isValidZone(zoneType) then return end
  if not checkCooldown(source, 'receiveReward', animalId) then
    notify(source, 'กรุณารอสักครู่ก่อนเก็บรางวัลตัวนี้ซ้ำ')
    return
  end

  local src = source
  if not isNearZone(src, zoneType) then
    notify(src, 'You are not near the zone')
    return
  end

  local charId = getCharId(src)
  if not charId then notify(src, 'Character not found'); return end

  local zone    = Config.Zones[zoneType]
  local rewards = zone.itemReward

  -- คืน state กลับเป็น 'receive' เมื่อจ่ายรางวัลไม่สำเร็จ (ให้ลองใหม่ได้)
  local function revertClaim()
    MySQL.update('UPDATE animal_farm SET state="receive" WHERE id=@id AND char_id=@cid AND state="claiming"',
      { id = animalId, cid = charId })
  end

  -- ── STEP 1: atomic claim — flip receive → claiming (ผู้ชนะ update เท่านั้นได้ไปต่อ) ──
  -- กัน retry/concurrent เก็บซ้ำ (double-claim → item dupe)
  -- เงื่อนไขเวลาพักหลังให้อาหารครบ ใส่ไว้ใน UPDATE เดียวกับการ claim เลย
  -- ถ้าแยกไปเช็คก่อนแล้วค่อย update จะมีช่องให้ยิงรัวตอนใกล้ครบเวลาแล้วผ่านสองครั้ง
  local readyDelay = tonumber(Config.readyDelay) or 0
  local readyBefore = now() - readyDelay

  MySQL.update(
    'UPDATE animal_farm SET state="claiming" WHERE id=@id AND char_id=@cid AND zone_type=@zone AND state="receive" AND last_fed <= @ready',
    { id = animalId, cid = charId, zone = zoneType, ready = readyBefore },
    function(claimed)
      if not claimed or claimed == 0 then
        -- แยกให้ออกว่า "ยังไม่ถึงเวลา" กับ "ยังไม่พร้อมเก็บ" — สองอย่างนี้คนละเรื่อง
        -- ถ้าบอกรวมกันผู้เล่นจะเห็น UI ขึ้นว่าพร้อมแล้วแต่กดไม่ได้ โดยไม่รู้ว่าต้องรอ
        MySQL.query(
          'SELECT state, last_fed FROM animal_farm WHERE id=@id AND char_id=@cid LIMIT 1',
          { id = animalId, cid = charId },
          function(rows)
            local row = rows and rows[1]
            if row and row.state == 'receive' and readyDelay > 0 then
              local left = math.max(0, (tonumber(row.last_fed) or 0) + readyDelay - now())
              notify(src, ('ยังเก็บไม่ได้ รออีก %d วินาที'):format(left))
            else
              notify(src, 'Animal not ready to collect')
            end
          end
        )
        return
      end

      -- ── STEP 2: precheck canCarry ทุกชิ้นก่อนจ่าย (กัน add fail กลางคัน) ──
      local canAll = true
      for _, reward in ipairs(rewards) do
        safeCanCarry(src, reward.name, reward.qty, function(res)
          if not res then canAll = false end   -- nil (error) หรือ false = พกไม่ได้
        end)
      end
      if not canAll then
        revertClaim()
        notify(src, 'ช่องเก็บของไม่พอ')
        return
      end

      -- ── STEP 3: จ่ายรางวัลทั้งหมด แล้วค่อย DELETE ──
      local total = #rewards
      local done  = 0
      local allOk = true
      for _, reward in ipairs(rewards) do
        local okAdd = pcall(function()
          exports.vorp_inventory:addItem(src, reward.name, reward.qty, nil, function(addOk)
            done = done + 1
            if not addOk then allOk = false end
            if done == total then
              if not allOk then
                revertClaim()
                notify(src, 'Failed to give reward, please try again')
                return
              end
              MySQL.update('DELETE FROM animal_farm WHERE id=@id AND char_id=@cid AND state="claiming"',
                { id = animalId, cid = charId },
                function(affected)
                  if not affected or affected == 0 then return end
                  TriggerClientEvent('animalfarm:animalRemoved', src, animalId)
                  notify(src, 'Reward collected!', 'success')
                end
              )
            end
          end)
        end)
        if not okAdd then
          allOk = false
          done  = done + 1
          if done == total then
            revertClaim()
            notify(src, 'Failed to give reward, please try again')
          end
        end
      end
    end
  )
end)

-- (ลบ event animalfarm:deleteAnimal ทิ้ง — สัตว์ตายแล้วถูกลบอัตโนมัติ ไม่มีปุ่ม DELETE ให้กดอีก)

-- ─── GLOBAL DECAY TICK ───────────────────────────────────────────────────────

CreateThread(function()
  while true do
    Wait(60000)
    local deadline = now() - Config.hpDecayTime - Config.feedWindow
    -- หา animals ที่กำลังจะตาย พร้อม char_id เพื่อ notify player
    MySQL.query(
      'SELECT id, char_id, zone_type FROM animal_farm WHERE state="feed" AND last_fed > 0 AND last_fed < @d',
      { d = deadline },
      function(rows)
        if not rows or #rows == 0 then return end
        -- เดิม mark state="dead" ค้างไว้ให้ผู้เล่นกดปุ่ม DELETE เอง — ตอนนี้ลบทิ้งเลยพร้อมแจ้งเตือน
        -- (ช่องในคอกจึงว่างทันที ไม่ต้องกลับมาเก็บกวาดเอง)
        MySQL.update(
          'DELETE FROM animal_farm WHERE state="feed" AND last_fed > 0 AND last_fed < @d',
          { d = deadline }
        )
        -- build charId → src map ครั้งเดียว (แทน getUser ซ้ำใน nested loop)
        local charToSrc = {}
        for _, playerId in ipairs(GetPlayers()) do
          local psrc = tonumber(playerId)
          local cid  = getCharId(psrc)
          if cid then charToSrc[cid] = psrc end
        end
        -- notify players ที่ online (lookup O(1))
        for _, row in ipairs(rows) do
          local src = charToSrc[row.char_id]
          if src then
            TriggerClientEvent('animalfarm:notify', src,
              'Your ' .. row.zone_type .. ' animal has died! (not fed in time)', 'error')
            TriggerClientEvent('animalfarm:animalDied', src, row.id)
          end
        end
      end
    )
  end
end)
