-- 0x4CC5F2FC1332577F is _ENABLE_HUD_CONTEXT (its old/legacy name was misleadingly
-- "_HIDE_HUD_COMPONENT" even though it turns the context ON). The one that actually
-- hides it is 0x8BC7C1F929D07BF3, _DISABLE_HUD_CONTEXT.
local DISABLE_HUD_CONTEXT = 0x8BC7C1F929D07BF3

-- GetHashKey never changes for the same string, so compute once instead of every tick
local hudComponents = {
    GetHashKey("HUD_CTX_CASH"),          -- เงิน (ดอลลาร์)
    GetHashKey("HUD_CTX_GOLD_BARS"),     -- ทอง
    GetHashKey("HUD_CTX_TOKENS"),        -- Role Tokens
    GetHashKey("HUD_CTX_HONOR_DISPLAY"), -- หลอด Honor
}

CreateThread(function()
    while true do
        Wait(0) -- must run every frame, the native only suppresses the popup for the current frame

        for i = 1, #hudComponents do
            Citizen.InvokeNative(DISABLE_HUD_CONTEXT, hudComponents[i])
        end
    end
end)
