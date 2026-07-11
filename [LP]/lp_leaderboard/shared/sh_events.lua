-- lp_leaderboard / shared/sh_events.lua
-- ชื่อ event รวมศูนย์ กัน typo (ใช้ทั้ง client/server)

Events = {
    -- client → server
    requestOpen = 'lp_leaderboard:SV:RequestOpen',
    close       = 'lp_leaderboard:SV:Close',
    -- รีเซ็ตสถิติทำผ่านคำสั่งแอดมิน /lbreset ตรงบน server (RegisterCommand) ไม่ผ่าน NUI/event แล้ว

    -- server → client
    openUI      = 'lp_leaderboard:CL:OpenUI',
    pushState   = 'lp_leaderboard:CL:PushState',

    -- lp_airdropteam (server) → lp_leaderboard (server) : สรุปผลรอบต่อเมือง
    -- payload: { cities = { {id=cityId, label=?}, ... }, winner = cityId | nil }
    cityResult  = 'lp_leaderboard:SV:CityRoundResult',

    -- ── "gather job" events (fish/mining/planting/lumber) ──────────────────
    -- ทุกตัวใช้ payload หน้าตาเดียวกัน: { src = ผู้เล่นที่ทำสำเร็จ, amount = จำนวนไอเทมที่ได้ }
    -- ต้องแนบ src มาเอง — TriggerEvent ข้าม resource ไม่รับประกัน global `source`
    fishCatch     = 'lp_leaderboard:SV:FishCatch',     -- MJ-AfkFishing (server.lua/giveReward)
    miningGather  = 'lp_leaderboard:SV:MiningGather',  -- MJ-Mining (server/server.lua/mining:addItem)
    plantHarvest  = 'lp_leaderboard:SV:PlantHarvest',  -- MJ-Planting (core/server.lua/Giveitem)
    lumberChop    = 'lp_leaderboard:SV:LumberChop',    -- MJ-Lumberjack (server/server.lua/!MJ-Lumberjack:addItem)
}
