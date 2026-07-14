LP_DM = LP_DM or {}
LP_DM.Rewards = {}

-- รางวัลตามอันดับเป็นของรับประกัน ไม่ใช่ loot roll แบบสุ่ม (ชนะแล้วควรได้แน่นอน ไม่ต้องมาเสี่ยงดวงซ้ำอีกชั้น)
-- tiedCount: ถ้าเสมอกันหลายเมือง หารเงินรางวัลเท่าๆ กัน — ส่วนไอเทมให้เต็มจำนวนทุกเมืองที่เสมอ (แบ่งไอเทมเป็นเศษส่วนไม่มีความหมาย)
function LP_DM.Rewards.GiveForRank(source, character, rankCfg, tiedCount)
    if not rankCfg then return end
    tiedCount = math.max(tiedCount or 1, 1)

    for _, item in ipairs(rankCfg.items or {}) do
        local amount = math.random(item.min or 1, item.max or item.min or 1)
        if LP_DM.VORP.CanCarryItem(source, item.name, amount) then
            if LP_DM.VORP.AddItem(source, item.name, amount, item.metadata) then
                LP_DM.Security.Log(source, 'reward', ('given_item:%s x%d'):format(item.name, amount))
            end
        else
            LP_DM.Security.Log(source, 'reward', 'inventory_full:' .. item.name)
        end
    end

    local money = rankCfg.money
    if money and money.enabled and (money.max or 0) > 0 then
        local amount = math.floor(math.random(money.min or 0, money.max or 0) / tiedCount)
        if amount > 0 then
            LP_DM.VORP.AddCurrency(character, money.currency or 0, amount)
            LP_DM.Security.Log(source, 'reward', ('given_money:%d'):format(amount))
        end
    end
end
