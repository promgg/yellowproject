local VORPcore = exports.vorp_core:GetCore()

-- Steam API Key อยู่ฝั่ง server เท่านั้น
local STEAM_API_KEY = '45C5DC4D05F27B314BCBB601533AAD91'

local function getSteam64(src)
  local hex = GetPlayerIdentifierByType(src, 'steam')
  if not hex then return nil end
  hex = hex:gsub('steam:', '')
  return tostring(tonumber(hex, 16))
end

local function fetchAvatar(steam64, cb)
  if not STEAM_API_KEY or STEAM_API_KEY == '' or not steam64 then
    cb(nil)
    return
  end
  local done = false
  local url = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=' .. STEAM_API_KEY .. '&steamids=' .. steam64
  PerformHttpRequest(url, function(code, body)
    if done then return end
    done = true
    if code ~= 200 or not body then cb(nil) return end
    local ok, data = pcall(json.decode, body)
    if not ok or not data then cb(nil) return end
    local players = data.response and data.response.players
    if players and players[1] then
      cb(players[1].avatarfull or players[1].avatarmedium or players[1].avatar)
    else
      cb(nil)
    end
  end, 'GET', '', { ['Content-Type'] = 'application/json' })
  -- fallback timeout 5 วิ กัน HTTP ค้าง
  SetTimeout(5000, function()
    if not done then done = true; cb(nil) end
  end)
end

-- per-source cooldown กัน spam Steam API
local cooldowns = {}
local COOLDOWN = 3000

RegisterServerEvent('Allmenu:requestOpen')
AddEventHandler('Allmenu:requestOpen', function()
  local src = source
  local now = GetGameTimer()
  if cooldowns[src] and now - cooldowns[src] < COOLDOWN then return end
  cooldowns[src] = now

  local user = VORPcore.getUser(src)
  if not user then return end
  local char = user.getUsedCharacter
  if not char then return end
  local name    = char.firstname .. ' ' .. char.lastname
  local steam64 = getSteam64(src)

  fetchAvatar(steam64, function(avatarUrl)
    TriggerClientEvent('Allmenu:open', src, name, src, avatarUrl)
  end)
end)

-- cleanup cooldown เมื่อ player ออก
AddEventHandler('playerDropped', function()
  cooldowns[source] = nil
end)
