local VORPcore = exports.vorp_core:GetCore()

local T = Translation.Langs[Config.Lang]

local fishEntity = {
    [`A_C_FISHBLUEGIL_01_MS`]        = { entity = "fish_bluegill_small", name = FishData.A_C_FISHBLUEGIL_01_MS[1], texture = FishData.A_C_FISHBLUEGIL_01_MS[2] },
    [`A_C_FISHBLUEGIL_01_SM`]        = { entity = "fish_bluegill_small", name = FishData.A_C_FISHBLUEGIL_01_SM[1], texture = FishData.A_C_FISHBLUEGIL_01_SM[2] },
    [`A_C_FISHBULLHEADCAT_01_MS`]    = { entity = "fish_bullheadcat_small", name = FishData.A_C_FISHBULLHEADCAT_01_MS[1], texture = FishData.A_C_FISHBULLHEADCAT_01_MS[2] },
    [`A_C_FISHBULLHEADCAT_01_SM`]    = { entity = "fish_bullheadcat_small", name = FishData.A_C_FISHBULLHEADCAT_01_SM[1], texture = FishData.A_C_FISHBULLHEADCAT_01_SM[2] },
    [`A_C_FISHCHAINPICKEREL_01_MS`]  = { entity = "fish_chainpickerel_small", name = FishData.A_C_FISHCHAINPICKEREL_01_MS[1], texture = FishData.A_C_FISHCHAINPICKEREL_01_MS[2] },
    [`A_C_FISHCHAINPICKEREL_01_SM`]  = { entity = "fish_chainpickerel_small", name = FishData.A_C_FISHCHAINPICKEREL_01_SM[1], texture = FishData.A_C_FISHCHAINPICKEREL_01_SM[2] },
    [`A_C_FISHCHANNELCATFISH_01_LG`] = { entity = "fish_channelcatfish_large", name = FishData.A_C_FISHCHANNELCATFISH_01_LG[1], texture = FishData.A_C_FISHCHANNELCATFISH_01_LG[2] },
    [`A_C_FISHCHANNELCATFISH_01_XL`] = { entity = "fish_channelcatfish_large", name = FishData.A_C_FISHCHANNELCATFISH_01_XL[1], texture = FishData.A_C_FISHCHANNELCATFISH_01_XL[2] },
    [`A_C_FISHLAKESTURGEON_01_LG`]   = { entity = "fish_lakesturgeon_large", name = FishData.A_C_FISHLAKESTURGEON_01_LG[1], texture = FishData.A_C_FISHLAKESTURGEON_01_LG[2] },
    [`A_C_FISHLARGEMOUTHBASS_01_LG`] = { entity = "fish_largemouthbass_medium", name = FishData.A_C_FISHLARGEMOUTHBASS_01_LG[1], texture = FishData.A_C_FISHLARGEMOUTHBASS_01_LG[2] },
    [`A_C_FISHLARGEMOUTHBASS_01_MS`] = { entity = "fish_largemouthbass_medium", name = FishData.A_C_FISHLARGEMOUTHBASS_01_MS[1], texture = FishData.A_C_FISHLARGEMOUTHBASS_01_MS[2] },
    [`A_C_FISHLONGNOSEGAR_01_LG`]    = { entity = "fish_longnosegar_large", name = FishData.A_C_FISHLONGNOSEGAR_01_LG[1], texture = FishData.A_C_FISHLONGNOSEGAR_01_LG[2] },
    [`A_C_FISHMUSKIE_01_LG`]         = { entity = "fish_muskie_large", name = FishData.A_C_FISHMUSKIE_01_LG[1], texture = FishData.A_C_FISHMUSKIE_01_LG[2] },
    [`A_C_FISHNORTHERNPIKE_01_LG`]   = { entity = "fish_northernpike_large", name = FishData.A_C_FISHNORTHERNPIKE_01_LG[1], texture = FishData.A_C_FISHNORTHERNPIKE_01_LG[2] },
    [`A_C_FISHPERCH_01_MS`]          = { entity = "fish_perch_small", name = FishData.A_C_FISHPERCH_01_MS[1], texture = FishData.A_C_FISHPERCH_01_MS[2] },
    [`A_C_FISHPERCH_01_SM`]          = { entity = "fish_perch_small", name = FishData.A_C_FISHPERCH_01_SM[1], texture = FishData.A_C_FISHPERCH_01_SM[2] },
    [`A_C_FISHRAINBOWTROUT_01_LG`]   = { entity = "fish_rainbowtrout_medium", name = FishData.A_C_FISHRAINBOWTROUT_01_LG[1], texture = FishData.A_C_FISHRAINBOWTROUT_01_LG[2] },
    [`A_C_FISHRAINBOWTROUT_01_MS`]   = { entity = "fish_rainbowtrout_medium", name = FishData.A_C_FISHRAINBOWTROUT_01_MS[1], texture = FishData.A_C_FISHRAINBOWTROUT_01_MS[2] },
    [`A_C_FISHREDFINPICKEREL_01_MS`] = { entity = "fish_redfinpickerel_small", name = FishData.A_C_FISHREDFINPICKEREL_01_MS[1], texture = FishData.A_C_FISHREDFINPICKEREL_01_MS[2] },
    [`A_C_FISHREDFINPICKEREL_01_SM`] = { entity = "fish_redfinpickerel_small", name = FishData.A_C_FISHREDFINPICKEREL_01_SM[1], texture = FishData.A_C_FISHREDFINPICKEREL_01_SM[2] },
    [`A_C_FISHROCKBASS_01_MS`]       = { entity = "fish_rockbass_small", name = FishData.A_C_FISHROCKBASS_01_MS[1], texture = FishData.A_C_FISHROCKBASS_01_MS[2] },
    [`A_C_FISHROCKBASS_01_SM`]       = { entity = "fish_rockbass_small", name = FishData.A_C_FISHROCKBASS_01_SM[1], texture = FishData.A_C_FISHROCKBASS_01_SM[2] },
    [`A_C_FISHSALMONSOCKEYE_01_LG`]  = { entity = "fish_salmonsockeye_medium", name = FishData.A_C_FISHSALMONSOCKEYE_01_LG[1], texture = FishData.A_C_FISHSALMONSOCKEYE_01_LG[2] },
    [`A_C_FISHSALMONSOCKEYE_01_ML`]  = { entity = "fish_salmonsockeye_medium", name = FishData.A_C_FISHSALMONSOCKEYE_01_ML[1], texture = FishData.A_C_FISHSALMONSOCKEYE_01_ML[2] },
    [`A_C_FISHSALMONSOCKEYE_01_MS`]  = { entity = "fish_salmonsockeye_medium", name = FishData.A_C_FISHSALMONSOCKEYE_01_MS[1], texture = FishData.A_C_FISHSALMONSOCKEYE_01_MS[2] },
    [`A_C_FISHSMALLMOUTHBASS_01_LG`] = { entity = "fish_smallmouthbass_medium", name = FishData.A_C_FISHSMALLMOUTHBASS_01_LG[1], texture = FishData.A_C_FISHSMALLMOUTHBASS_01_LG[2] },
    [`A_C_FISHSMALLMOUTHBASS_01_MS`] = { entity = "fish_smallmouthbass_medium", name = FishData.A_C_FISHSMALLMOUTHBASS_01_MS[1], texture = FishData.A_C_FISHSMALLMOUTHBASS_01_MS[2] },
}


local playersFishing = {}

-- ตรวจฝั่ง server ว่าอยู่ในเขตห้ามตกปลาไหม — กันคนยิง event ตรงข้าม gate ของ client
-- (client เช็คให้ prompt ไม่ขึ้นอยู่แล้ว แต่ห้ามเชื่อ client เรื่องตำแหน่ง)
-- ต้องนิยามก่อน CreateThread ด้านล่าง ไม่งั้น closure ของ usable bait มองไม่เห็น local นี้
local function serverInNoFishZone(src)
    local zones = Config.NoFishZones
    if not zones then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)

    for _, z in ipairs(zones) do
        local dx, dy = c.x - z.coords.x, c.y - z.coords.y
        if (dx * dx + dy * dy) <= (z.radius * z.radius) then
            return true
        end
    end
    return false
end

CreateThread(function()
    for _, item in ipairs(Baits) do
        exports.vorp_inventory:registerUsableItem(item, function(data)
            local _source = data.source

            -- เขตห้ามตกปลา (โซนรอบไร่ปลูกผัก) — เช็คก่อนหักเหยื่อ ไม่งั้นเหยื่อหายฟรี
            -- โหมดผสมเริ่มจากการใช้เหยื่อตรงนี้ ไม่ผ่าน equipRod เลยต้อง gate ที่นี่ด้วย
            if serverInNoFishZone(_source) then
                exports.vorp_inventory:closeInventory(_source)
                TriggerClientEvent('pNotify:SendNotification', _source, {
                    text = 'ห้ามตกปลาในเขตนี้', type = 'error', timeout = 4000, layout = 'topRight',
                })
                return
            end

            playersFishing[_source] = true
            exports.vorp_inventory:closeInventory(_source)

            local result <const> = VORPcore.Callback.TriggerAwait("lp_fishing:checkRodAndBait", _source, item)

            if not result[1] then
                return
            else
                exports.vorp_inventory:subItem(_source, result[2], 1)
                TriggerClientEvent("lp_fishing:UseBait", _source, result[2])
            end

        end, GetCurrentResourceName())
    end
end)

RegisterServerEvent("lp_fishing:stopFishing", function()
    if playersFishing[source] then
        playersFishing[source] = nil
    end
end)

RegisterServerEvent("lp_fishing:FishToInventory", function(netid, fishModel, fishWeight, status)
    local _source = source
    if not playersFishing[_source] then
        return print("Player is not fishing and tried to give item to inventory", GetPlayerName(_source))
    end

    local entity = NetworkGetEntityFromNetworkId(netid)
    if not DoesEntityExist(entity) then return print("Entity does not exist", netid) end

    -- กันช่องโหว่ dupe/ลบของคนอื่น: เดิมเชื่อ netid/fishModel ที่ client ส่งมาตรงๆ ทั้งหมด
    -- ผู้เล่นที่แก้ client เอง ส่ง netid ของ entity อะไรก็ได้ (ของผู้เล่นอื่น/ม้า/รถ) พร้อม fishModel
    -- ปลาราคาแพงมา ก็จะได้ไอเทมฟรี + สั่งลบ entity นั้นทิ้งได้เลย (DeleteEntity ไม่เช็คอะไรก่อน)
    -- เช็คเพิ่ม 3 อย่าง: entity ต้องเป็น ped จริง, model ต้องตรงกับที่อ้าง, ต้องอยู่ใกล้ผู้เล่นคนนั้นจริง
    if GetEntityType(entity) ~= 1 then
        return print("Claimed fish entity is not a ped", netid, GetPlayerName(_source))
    end

    local actualModel = GetEntityModel(entity)
    if actualModel ~= fishModel then
        return print("Claimed fishModel does not match entity's real model", netid, fishModel, actualModel, GetPlayerName(_source))
    end

    local ped = GetPlayerPed(_source)
    local dist = #(GetEntityCoords(entity) - GetEntityCoords(ped))
    if dist > 15.0 then
        return print("Claimed fish entity too far from player", netid, dist, GetPlayerName(_source))
    end

    local fish = fishEntity[fishModel]
    if not fish then return print("Fish model not found in table fishEntity", fishModel) end
    local fish_name = fish.name
    if not fish_name then return print("Fish name not found in table fishNames", fishModel) end
    local fish_texture = fish.texture
    if not fish_texture then return print("Fish texture not found in table fishTextures", fishModel) end

    local canCarry = exports.vorp_inventory:canCarryItem(_source, fish.entity, 1)
    if not canCarry then
        VORPcore.NotifyObjective(_source, T.CannotCarryMore, 4000)
        -- ลบปลาทิ้งด้วยแม้เก็บไม่ได้ ไม่งั้น prop จะลอยค้างอยู่ปลายเบ็ด
        if DoesEntityExist(entity) then DeleteEntity(entity) end
        return
    end

    if Config.DiscordIntegration then
        TriggerEvent("lp_fishing:discord", fishModel, fishWeight, status, _source)
    end

    exports.vorp_inventory:addItem(_source, fish.entity, 1)
    -- ปิดแจ้งเตือน "You got a <ชื่อปลา>" ของ vorp — ชื่อปลายังเป็นอังกฤษจาก fishData.lua
    -- และซ้ำกับ notification ที่ผู้เล่นเห็นอยู่แล้วตอนได้ไอเทม
    -- VORPcore.NotifyAvanced(_source, T.YourGot .. " " .. fish_name, "inventory_items", fish_texture, "COLOR_PURE_WHITE", 4000)

    -- ลบ prop ปลาจากฝั่ง server ทันทีหลังแจกของ (pattern เดียวกับ lp_hunting)
    -- เดิมพึ่ง client ที่ Wait(3000) ก่อนลบ — ถ้าผู้เล่นหลุด/resource restart ในช่วงนั้น prop จะค้างในโลก
    -- client ยังลบซ้ำอีกชั้นเป็นตาข่ายสำรอง (ลบซ้ำไม่มีผลเสีย มี DoesEntityExist กันอยู่)
    if DoesEntityExist(entity) then DeleteEntity(entity) end

    -- lp_leaderboard (FISH RANK): soft integration — ยิงเฉยๆ ไม่ต้อง depend เงียบถ้าไม่มี resource นี้
    -- ต้องแนบ src เอง เพราะ TriggerEvent ข้าม resource ไม่รับประกัน global source ฝั่งผู้รับ
    TriggerEvent('lp_leaderboard:SV:FishCatch', { src = _source, amount = 1 })

    -- flash ช่องปลาที่เพิ่งได้ใน lp_rewardpanel (ยิงหลังยืนยันว่าเข้ากระเป๋าจริงแล้วเท่านั้น)
    TriggerClientEvent('lp_fishing:fishAwarded', _source, fish.entity)
end)

AddEventHandler("playerDropped", function()
    local _source = source
    if playersFishing[_source] then
        playersFishing[_source] = nil
    end
end)

RegisterNetEvent("lp_fishing:discord")
AddEventHandler('lp_fishing:discord', function(fishModel, fishWeight, status, src)
    local _source = src

    local Character = VORPcore.getUser(_source).getUsedCharacter
    local fish = fishEntity[fishModel]
    if not fish then return print("Fish model not found in table fishEntity", fishModel) end

    local fish_name = fish.name
    local fish_weight = string.format("%.2f%%", (fishWeight * 54.25))
    local webhook = "" -- link here for webhook
    local botname = Config.DiscordBotName
    local avatar = Config.DiscordAvatar
    local footerlogo = Config.DiscordFooterLogo
    local color = 4777493
    local CharName = "Unknown Player"
    local _description = ""

     if Character then
        CharName = Character.firstname .. ' ' .. Character.lastname
    end

    if status == "keep" then
        _description = T.discord_fishKept
    elseif status == "throw" then
        _description = T.discord_fishThrow
    end

    local title = CharName .. " " .. T.discord_fishCaught
    local description = _description .. "\n" .. T.discord_fieldFishName .. ": " .. fish_name .. "\n" .. T.discord_fieldFishWeight .. ": " .. fish_weight .. "Kg"

    VORPcore.AddWebhook(title, webhook, description, color, botname, footerlogo, avatar)
end)
-- ═══════════════════════════════════════════════════════════════════════════
--  lp_fishing — ส่วนที่เพิ่มจาก vorp_fishing เดิม
-- ═══════════════════════════════════════════════════════════════════════════

-- client กด [E] ที่ prompt lp_textui -> ขอหยิบเบ็ด
-- server ตรวจเองว่ามีเบ็ดจริงในคลังอาวุธก่อนสั่งหยิบ (client บอกได้แค่ "ขอ" ไม่ได้บอกว่ามี)
RegisterServerEvent('lp_fishing:equipRod', function()
    local _source = source

    if serverInNoFishZone(_source) then
        TriggerClientEvent('pNotify:SendNotification', _source, {
            text = 'ห้ามตกปลาในเขตนี้', type = 'error', timeout = 4000, layout = 'topRight',
        })
        return
    end

    local ok, weapons = pcall(function()
        return exports.vorp_inventory:getUserInventoryWeapons(_source)
    end)
    if not ok or type(weapons) ~= 'table' then return end

    local rodName = Config.RodWeapon or 'WEAPON_FISHINGROD'
    for _, w in pairs(weapons) do
        if w.name == rodName then
            TriggerClientEvent('lp_fishing:doEquipRod', _source)
            return
        end
    end

    TriggerClientEvent('pNotify:SendNotification', _source, {
        text = 'คุณไม่มีเบ็ดตกปลา', type = 'error', timeout = 4000, layout = 'topRight',
    })
end)
