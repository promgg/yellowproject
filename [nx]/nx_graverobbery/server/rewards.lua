NX_GR = NX_GR or {}
NX_GR.Rewards = {}

local function rollWeighted(items)
    local total = 0
    for _, item in ipairs(items or {}) do
        total = total + (item.weight or 0)
    end
    if total <= 0 then return nil end

    local roll = math.random(1, total)
    local cursor = 0
    for _, item in ipairs(items) do
        cursor = cursor + (item.weight or 0)
        if roll <= cursor then return item end
    end
    return nil
end

function NX_GR.Rewards.Give(source, character, grave)
    local pool = Config.RewardPools[grave.rewardPool]
    if not pool then
        NX_GR.Security.Log(source, 'reward', 'missing_pool', { character = character, graveId = grave.id, villageId = grave.villageId })
        return false
    end

    if math.random(1, 100) <= (pool.emptyChance or 0) then
        NX_GR.VORP.Notify(source, NX_GR.Locale('empty'))
        return true
    end

    local selected = rollWeighted(pool.items)
    if selected then
        local amount = math.random(selected.min or 1, selected.max or selected.min or 1)
        if not NX_GR.VORP.CanCarryItem(source, selected.name, amount) then
            NX_GR.VORP.Notify(source, NX_GR.Locale('inventory_full'))
            NX_GR.Security.Log(source, 'reward', 'inventory_full', { character = character, graveId = grave.id, villageId = grave.villageId })
            return false
        end

        if not NX_GR.VORP.AddItem(source, selected.name, amount, selected.metadata) then
            NX_GR.Security.Log(source, 'reward', 'add_item_failed', { character = character, graveId = grave.id, villageId = grave.villageId })
            return false
        end

        NX_GR.VORP.Notify(source, NX_GR.Locale('received_item', { amount = amount, item = selected.name }))
    end

    local money = pool.money
    if money and money.enabled and (money.max or 0) > 0 then
        local amount = math.random(money.min or 0, money.max or 0)
        if amount > 0 then
            NX_GR.VORP.AddCurrency(character, money.currency or 0, amount)
        end
    end

    return true
end
