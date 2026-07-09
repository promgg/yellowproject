local VORPcore = exports.vorp_core:GetCore()

-- ────────────────────────────────────────────
--  DB: สร้างตารางถ้ายังไม่มี
-- ────────────────────────────────────────────

MySQL.ready(function()
  MySQL.query([[
    CREATE TABLE IF NOT EXISTS `dailyquest_progress` (
      `identifier` VARCHAR(60)  NOT NULL,
      `quest_key`  VARCHAR(40)  NOT NULL,
      `current`    INT          NOT NULL DEFAULT 0,
      `quest_date` DATE         NOT NULL,
      PRIMARY KEY (`identifier`, `quest_key`, `quest_date`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  ]])
end)

-- ────────────────────────────────────────────
--  Rate Limiting
-- ────────────────────────────────────────────

local cooldowns   = {}
local COOLDOWN_MS = {
  requestQuests = 2000,
  addProgress   = 500,
}

local function checkCooldown(src, action)
  local t = GetGameTimer()
  if not cooldowns[src] then cooldowns[src] = {} end
  local last = cooldowns[src][action] or 0
  if (t - last) < COOLDOWN_MS[action] then return false end
  cooldowns[src][action] = t
  return true
end

AddEventHandler('playerDropped', function()
  cooldowns[source] = nil
end)

-- ────────────────────────────────────────────
--  Helpers
-- ────────────────────────────────────────────

local function getIdentifier(src)
  local user = VORPcore.getUser(src)
  if not user then return nil end
  return user.getIdentifier()
end

local function todayDate()
  return os.date('%Y-%m-%d')
end

-- ดึง progress ของผู้เล่น แล้วรวมกับ Config สร้าง quest list สำหรับส่ง UI
local function buildQuestList(identifier, cb)
  local today = todayDate()
  MySQL.query(
    'SELECT quest_key, current FROM dailyquest_progress WHERE identifier = ? AND quest_date = ?',
    { identifier, today },
    function(rows)
      if not rows then rows = {} end  -- Phase 4: nil guard
      local progress = {}
      for _, row in ipairs(rows) do
        progress[row.quest_key] = row.current
      end

      local list = {}
      for _, key in ipairs(Config.QuestOrder) do
        local cfg = Config.Quests[key]
        if cfg then
          list[#list + 1] = {
            key     = key,
            name    = cfg.name,
            desc    = cfg.desc,
            img     = cfg.img,
            current = progress[key] or 0,
            target  = cfg.target,
          }
        end
      end
      cb(list)
    end
  )
end

-- ────────────────────────────────────────────
--  Event: ผู้เล่นขอเปิด UI
-- ────────────────────────────────────────────

RegisterServerEvent('Daliyquest:server:requestQuests')
AddEventHandler('Daliyquest:server:requestQuests', function()
  local src = source
  if not checkCooldown(src, 'requestQuests') then return end

  local identifier = getIdentifier(src)
  if not identifier then return end

  buildQuestList(identifier, function(list)
    TriggerClientEvent('Daliyquest:client:openQuest', src, list)
  end)
end)

-- ────────────────────────────────────────────
--  Core: เพิ่ม progress เควส (ใช้ทั้ง event และ export)
--  เรียกจาก script อื่น:
--    TriggerServerEvent('Daliyquest:server:addProgress', 'plant', 1)
--    exports.Daliyquest:addProgress(src, 'hunt', 1)
-- ────────────────────────────────────────────

local function doAddProgress(src, questKey, amount)
  -- Phase 3: validate inputs
  if type(questKey) ~= 'string' then return end
  amount = math.max(1, math.floor(tonumber(amount) or 1))

  local identifier = getIdentifier(src)
  if not identifier then return end
  if not Config.Quests[questKey] then return end

  local today = todayDate()
  local cfg   = Config.Quests[questKey]

  -- Phase 6: SELECT ก่อนเพื่อตรวจ reward threshold แล้วใช้ UPSERT แทน SELECT+UPDATE/INSERT
  MySQL.query(
    'SELECT current FROM dailyquest_progress WHERE identifier = ? AND quest_key = ? AND quest_date = ?',
    { identifier, questKey, today },
    function(rows)
      if not rows then rows = {} end  -- Phase 4: nil guard
      local current = rows[1] and rows[1].current or 0

      -- หยุดถ้าเสร็จแล้ว
      if current >= cfg.target then return end

      local newVal   = math.min(current + amount, cfg.target)
      local justDone = newVal >= cfg.target

      -- Phase 6: UPSERT แทน UPDATE/INSERT แยก — ลด query จาก 2 → 1
      MySQL.query(
        [[INSERT INTO dailyquest_progress (identifier, quest_key, current, quest_date)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE current = LEAST(current + ?, ?)]],
        { identifier, questKey, newVal, today, amount, cfg.target }
      )

      -- Phase 1: ให้ reward เมื่อเควสเสร็จ
      if justDone and cfg.reward then
        for _, r in ipairs(cfg.reward) do
          exports.vorp_inventory:addItem(src, r.name, r.qty, nil, function(ok)
            if ok then
              TriggerClientEvent('vorp:TipBottom', src,
                'เควส ' .. cfg.name .. ' สำเร็จ! ได้รับ ' .. r.qty .. 'x ' .. r.name, 4000)
            end
          end)
        end
      end

      -- push update ให้ UI
      buildQuestList(identifier, function(list)
        TriggerClientEvent('Daliyquest:client:updateQuest', src, list)
      end)
    end
  )
end

-- Phase 2+3: เหลือ handler เดียว (ลบ duplicate handler ที่ทำให้ progress +2x)
RegisterServerEvent('Daliyquest:server:addProgress')
AddEventHandler('Daliyquest:server:addProgress', function(questKey, amount)
  local src = source
  if not checkCooldown(src, 'addProgress') then return end
  doAddProgress(src, questKey, amount)
end)

exports('addProgress', function(src, questKey, amount)
  doAddProgress(src, questKey, amount)
end)

-- ────────────────────────────────────────────
--  Hook: MJ-Planting — เก็บแครอท 1 ต้น = +1 plant
-- ────────────────────────────────────────────

AddEventHandler('MJ-Planting:Giveitem', function(ITEM)
  if ITEM == 'carrot_seed' then
    doAddProgress(source, 'plant', 1)
  end
end)

-- ────────────────────────────────────────────
--  Hook: MJ-Mining — ขุดสำเร็จ 1 ครั้ง = +1 mine
-- ────────────────────────────────────────────

RegisterNetEvent('mining:giveItem')
AddEventHandler('mining:giveItem', function(item, amount)
  if item == 'copper' or item == 'iron' then
    doAddProgress(source, 'mine', amount)
  end
end)
