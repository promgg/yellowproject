local isOpen = false

-- ────────────────────────────────────────────
--  Helpers
-- ────────────────────────────────────────────

local function showUI(quests)
  SendNUIMessage({
    action      = 'openQuest',
    quests      = quests,
    toggleCmd   = Config.ToggleCommand,  -- ส่ง command name ให้ UI แสดงถูกต้อง
  })
  isOpen = true
end

local function hideUI()
  SendNUIMessage({ action = 'closeQuest' })
  isOpen = false
end

-- ────────────────────────────────────────────
--  Command
-- ────────────────────────────────────────────

RegisterCommand(Config.ToggleCommand, function()
  if isOpen then
    hideUI()
  else
    TriggerServerEvent('Daliyquest:server:requestQuests')
  end
end, false)

-- ────────────────────────────────────────────
--  Server → Client events
-- ────────────────────────────────────────────

RegisterNetEvent('Daliyquest:client:openQuest', function(quests)
  showUI(quests)
end)

RegisterNetEvent('Daliyquest:client:updateQuest', function(quests)
  if not isOpen then return end
  SendNUIMessage({ action = 'updateQuest', quests = quests })
end)
