-- lp_battlepass — event name namespace: <resource>:<side>:<action>
-- side: sv = client->server, cl = server->client, cb = vorp callback
local res = GetCurrentResourceName()

Events = {
    -- client -> server (ทุกตัวมี cooldown + validate ฝั่ง server)
    requestOpen    = res .. ':sv:requestOpen',
    reward         = res .. ':sv:reward',
    rewardVIP      = res .. ':sv:rewardVIP',
    claimAllReward = res .. ':sv:claimAllReward',

    -- server -> client
    noti           = res .. ':cl:noti',
    openUI         = res .. ':cl:openUI',
    pushState      = res .. ':cl:pushState',

    -- local (client only) — lp_allmenu / command เรียกตัวนี้
    openBattlePass = res .. ':cl:openBattlePass',

    -- server -> server (public API ให้ resource อื่น hook เช่น lp_daliyquest)
    addXP          = res .. ':sv:addXP',
}
