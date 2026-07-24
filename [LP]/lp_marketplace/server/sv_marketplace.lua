-- sv_marketplace.lua — Business logic (VORPCore + vorp_inventory)
-- Ported from rimlay-marketplace (ESX): atomic UPDATE race-guards, type validation,
-- cooldowns, search limit, pcall DB — all preserved as-is.

-- ── Per-player cooldowns (server-side) ────────────────────────────────────────
local buyCooldowns      = {}
local cancelCooldowns   = {}
local claimCooldowns    = {}
local listingsCooldowns = {} -- server-side rate limit backstop (client already debounces at 350ms)
local COOLDOWN_BUY       = 2
local COOLDOWN_CANCEL    = 1
local COOLDOWN_CLAIM     = 1
local COOLDOWN_LISTINGS  = 1

local function CheckCooldown(tbl, src, seconds)
    local now = os.time()
    if tbl[src] and now - tbl[src] < seconds then return false end
    tbl[src] = now
    return true
end

local function GetCategoryForItem(itemName)
    return Config.ItemPriceConfig[itemName] and Config.ItemPriceConfig[itemName].category or 'general'
end

-- money → currency type 0 (dollars), gold → currency type 1 — ดู config/config_items.lua
local function CurrencyType(currency)
    local cfg = Config.AllowedCurrencies[currency]
    return cfg and cfg.currencyType or 0
end

local function GetBalance(Character, currency)
    return CurrencyType(currency) == 1 and (Character.gold or 0) or (Character.money or 0)
end

-- แทน VORPcore.NotifyRightTip เดิมทั้งหมด — ยิงตรงไปที่ pNotify ฝั่ง client
local function Notify(src, msg, msgType)
    TriggerClientEvent('pNotify:SendNotification', src, {
        text    = msg,
        type    = msgType or 'error',
        timeout = 4000,
    })
end

-- ── ลงขายสินค้า ───────────────────────────────────────────────────────────────
RegisterServerEvent('lp_marketplace:listItem')
AddEventHandler('lp_marketplace:listItem', function(data)
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    -- Type validation (fix: quantity float/string, price string)
    data.itemName      = tostring(data.itemName or '')
    data.quantity      = math.floor(tonumber(data.quantity) or 0)
    data.price         = math.floor(tonumber(data.price) or 0)
    data.currency      = tostring(data.currency or '')
    data.durationIndex = math.floor(tonumber(data.durationIndex) or 1)

    if data.itemName == '' or data.quantity <= 0 or data.price <= 0 or data.currency == '' then
        Notify(src, Config.Locale.listed_fail)
        return
    end

    -- Validate (anti-cheat)
    local ok, reason = ValidateListing(src, data.itemName, data.quantity, data.price, data.currency)
    if not ok then
        Notify(src,
            reason == 'rate_limited' and Config.Locale.rate_limited or Config.Locale.listed_fail)
        return
    end

    -- Job restriction
    local restrict = Config.RestrictedItems[data.itemName]
    if restrict then
        local allowed = false
        for _, job in ipairs(restrict.jobs) do
            if Character.job == job then allowed = true; break end
        end
        if not allowed then
            Notify(src, Config.Locale.restricted_item)
            return
        end
    end

    -- Currency allowed
    if not (Config.AllowedCurrencies[data.currency] and Config.AllowedCurrencies[data.currency].enabled) then
        Notify(src, Config.Locale.listed_fail)
        return
    end

    local charIdentifier = Character.charIdentifier

    -- Max listings check
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM lp_marketplace WHERE seller_id = ? AND status = ?',
        { charIdentifier, 'active' })
    if (count or 0) >= Config.MaxListingsPerPlayer then
        Notify(src,
            string.format(Config.Locale.max_listings, Config.MaxListingsPerPlayer))
        return
    end

    -- ปิด TOCTOU gap ระหว่าง ValidateListing (เช็ค count) กับจุดนี้ (มี await max-listings COUNT คั่น)
    local ownedCount = InvGetCount(src, data.itemName)
    if ownedCount < data.quantity then
        Notify(src, Config.Locale.listed_fail)
        return
    end

    local itemLabel = InvGetItemLabel(data.itemName)
    local category  = GetCategoryForItem(data.itemName)
    -- ตัวเลือกอาจตั้งเป็นวัน (เช่น { value = 7, unit = 'day' }) ต้องผ่าน ResolveDuration
    -- ก่อนเสมอ ไม่งั้นได้ table มาคูณ 3600 ตรงๆ
    local option = Config.DurationOptions[data.durationIndex] or Config.DurationOptions[1]
    local durationHours, durationLabel = ResolveDuration(option)
    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + durationHours * 3600)

    if not InvSubItem(src, data.itemName, data.quantity) then
        Notify(src, Config.Locale.listed_fail)
        return
    end

    -- pcall DB insert
    local ok2, insertId = pcall(function()
        return MySQL.insert.await(
            'INSERT INTO lp_marketplace (seller_id,seller_name,item_name,item_label,category,quantity,price,currency,expires_at) VALUES (?,?,?,?,?,?,?,?,?)',
            { charIdentifier, GetPlayerName(src), data.itemName, itemLabel,
              category, data.quantity, data.price, data.currency, expiresAt })
    end)

    if ok2 and insertId then
        Notify(src, Config.Locale.listed_success, 'success')
        TriggerClientEvent('lp_marketplace:refreshSell', src)
        Log('list', '📦 ลงขายสินค้า',
            ('**%s** ลงขาย **%s** x%d ราคา **%d** (%s) %s'):format(
                GetPlayerName(src), itemLabel, data.quantity, data.price, data.currency, durationLabel))
    else
        InvAddItem(src, data.itemName, data.quantity)
        Notify(src, Config.Locale.listed_fail)
    end
end)

-- ── ดึงรายการสินค้า (BUY tab) ─────────────────────────────────────────────────
RegisterServerEvent('lp_marketplace:getListings')
AddEventHandler('lp_marketplace:getListings', function(data)
    local src = source
    if not CheckCooldown(listingsCooldowns, src, COOLDOWN_LISTINGS) then return end
    local category = tostring(data and data.category or 'all')
    local search   = tostring(data and data.search   or ''):sub(1, 50)
    local page     = math.max(1, math.floor(tonumber(data and data.page or 1) or 1))
    local offset   = (page - 1) * Config.ItemsPerPage

    local where  = { 'status = ?' }
    local params = { 'active' }

    if category ~= 'all' then
        where[#where+1]  = 'category = ?'
        params[#params+1] = category
    end
    if search ~= '' then
        where[#where+1]  = '(item_label LIKE ? OR seller_name LIKE ?)'
        params[#params+1] = '%' .. search .. '%'
        params[#params+1] = '%' .. search .. '%'
    end

    local whereStr = table.concat(where, ' AND ')
    local total    = MySQL.scalar.await('SELECT COUNT(*) FROM lp_marketplace WHERE ' .. whereStr, params)

    local queryParams = {}
    for _, v in ipairs(params) do queryParams[#queryParams+1] = v end
    queryParams[#queryParams+1] = Config.ItemsPerPage
    queryParams[#queryParams+1] = offset

    local rows = MySQL.query.await(
        'SELECT id,seller_name,item_name,item_label,category,quantity,price,currency,expires_at FROM lp_marketplace WHERE '
        .. whereStr .. ' ORDER BY created_at DESC LIMIT ? OFFSET ?',
        queryParams)

    TriggerClientEvent('lp_marketplace:receiveListings', src, {
        listings     = rows  or {},
        total        = total or 0,
        page         = page,
        itemsPerPage = Config.ItemsPerPage,
    })
end)

-- ── ซื้อสินค้า (core) — คืน ok(boolean), จัดการ notify/refresh/log ภายใน ────────
local DoBuyInner

local function DoBuy(src, listingId, buyQty)
    local ok, result = pcall(DoBuyInner, src, listingId, buyQty)
    if not ok then
        print(('[lp_marketplace] DoBuy error (src=%s listingId=%s): %s'):format(
            tostring(src), tostring(listingId), tostring(result)))
        Notify(src, Config.Locale.buy_fail)
        return false
    end
    return result
end

DoBuyInner = function(src, listingId, buyQty)
    local Character = GetCharacter(src)
    if not Character then return false end

    listingId = tonumber(listingId)
    buyQty    = math.floor(tonumber(buyQty) or 1)
    if not listingId or buyQty < 1 then return false end
    if not CheckCooldown(buyCooldowns, src, COOLDOWN_BUY) then return false end

    local listing = MySQL.single.await(
        'SELECT id,seller_id,seller_name,item_name,item_label,quantity,price,currency FROM lp_marketplace WHERE id=? AND status=? AND expires_at>NOW() LIMIT 1',
        { listingId, 'active' })

    if not listing then
        Notify(src, Config.Locale.buy_fail)
        return
    end

    -- tostring() ทั้งสองฝั่ง: Character.charIdentifier เป็น number (characters.charidentifier
    -- คือ int(11) ใน DB) แต่ listing.seller_id อ่านมาจาก lp_marketplace.seller_id ซึ่งเป็น
    -- VARCHAR(64) → oxmysql คืนมาเป็น string เทียบ "42" == 42 ตรงๆ ด้วย Lua == จะเป็น false
    -- เสมอ (คนละชนิดข้อมูล) ทำให้ป้องกันซื้อของตัวเองไม่ได้จริงตามที่ควรจะเป็น
    if tostring(listing.seller_id) == tostring(Character.charIdentifier) then
        Notify(src, Config.Locale.cannot_buy_own)
        return
    end

    -- clamp buyQty ไม่ให้เกิน stock จริง
    buyQty = math.min(buyQty, listing.quantity)

    local totalPrice = listing.price * buyQty

    -- กระเป๋าต้องรับของได้ก่อนคิดเงิน ไม่งั้นจ่ายแล้ว InvAddItem คืน false = เสียเงินฟรี
    -- (เป็น await เลยต้องอยู่ก่อนด่านเช็คยอดเงิน ไม่ใช่หลัง)
    if not InvCanCarry(src, listing.item_name, buyQty) then
        Notify(src, Config.Locale.buy_fail)
        return
    end

    -- ต้องหยิบ Character ใหม่หลัง await ทุกครั้ง: GetCharacter คืน "สำเนา" ที่ copy money/gold
    -- มาแบบ by-value ตัวที่หยิบไว้ตอนต้นฟังก์ชันจึงค้างยอดเก่าตั้งแต่ก่อน query listing
    -- (TOCTOU: ใช้เงินไปกับ resource อื่นระหว่างรอ await แล้วเช็คนี้ยังผ่านด้วยยอดก่อนหน้า)
    Character = GetCharacter(src)
    if not Character then return false end

    local balance = GetBalance(Character, listing.currency)
    if balance < totalPrice then
        Notify(src, Config.Locale.not_enough_money)
        return
    end

    local tax = CalcTax(totalPrice)

    -- 🔒 หักเงินตรงนี้ ก่อนเขียน DB — จากด่านเช็คยอดข้างบนถึงบรรทัดนี้ไม่มี await คั่น
    -- จึงไม่มีช่องให้แทรกใช้เงินที่อื่น
    --
    -- เดิมเขียน DB ก่อน (mark sold / ลด quantity / insert แถว sold ซึ่งเป็น await หลายตัว)
    -- แล้วหักเงินท้ายสุด ระหว่างรอ await ผู้เล่นใช้เงินกับ resource อื่นได้ พอกลับมา
    -- removeCurrency จะถูก clamp เหลือ 0 (vorp_core กันติดลบไว้) = ได้ของโดยจ่ายไม่ครบ
    local buyerCharId = Character.charIdentifier
    Character.removeCurrency(CurrencyType(listing.currency), totalPrice)

    -- คืนเงินให้ "ตัวละครที่จ่ายไป" เท่านั้น กันคืนผิดตัวถ้าสลับตัวละครระหว่างรอ DB
    local function refundBuyer(reason)
        local back = GetCharacter(src)
        if back and tostring(back.charIdentifier) == tostring(buyerCharId) then
            back.addCurrency(CurrencyType(listing.currency), totalPrice)
        else
            Log('buy', '⚠️ คืนเงินไม่ได้',
                ('charid **%s** จ่าย %d (%s) แล้ว %s แต่ตัวละครหลุด/สลับ ต้องคืนมือ'):format(
                    tostring(buyerCharId), totalPrice, listing.currency, reason))
        end
    end

    if buyQty == listing.quantity then
        -- ── ซื้อทั้งหมด: atomic mark sold (guard ด้วย quantity เดิมกัน race กับ partial buy) ──
        local affected = MySQL.update.await(
            'UPDATE lp_marketplace SET status=?,buyer_id=?,buyer_name=?,sold_at=NOW() WHERE id=? AND status=? AND quantity=?',
            { 'sold', Character.charIdentifier, GetPlayerName(src), listingId, 'active', listing.quantity })

        if not affected or affected == 0 then
            refundBuyer('mark-sold ไม่ผ่าน (มีคนซื้อตัดหน้า)')
            Notify(src, Config.Locale.buy_fail)
            return
        end
    else
        -- ── ซื้อบางส่วน: atomic reduce quantity → จ่ายเงินผู้ขายทันที ──────────
        local affected = MySQL.update.await(
            'UPDATE lp_marketplace SET quantity=quantity-? WHERE id=? AND status=? AND quantity>=?',
            { buyQty, listingId, 'active', buyQty })

        if not affected or affected == 0 then
            refundBuyer('ลด quantity ไม่ผ่าน (ของหมด/มีคนซื้อตัดหน้า)')
            Notify(src, Config.Locale.buy_fail)
            return
        end

        -- เงินผู้ขายต้องกด claim ผ่านแท็บ ITEM เสมอ ไม่ว่าจะ online ตอนซื้อหรือไม่ (ดีไซน์ตั้งใจ
        -- ให้เหมือน full-buy ทุกกรณี ไม่ใช่จ่ายทันทีตอน online) — INSERT แถวใหม่แยกจาก listing
        -- เดิมเสมอ เพราะ listing เดิมยัง status='active' ขายต่อได้ (ไม่ใช่ปิดเหมือน full-buy)
        MySQL.insert.await(
            'INSERT INTO lp_marketplace (seller_id,seller_name,buyer_id,buyer_name,item_name,item_label,category,quantity,price,currency,status,sold_at,expires_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,NOW(),NOW())',
            { listing.seller_id, listing.seller_name, Character.charIdentifier, GetPlayerName(src),
              listing.item_name, listing.item_label, GetCategoryForItem(listing.item_name),
              buyQty, listing.price, listing.currency, 'sold' })
    end

    -- ให้ของ (เงินหักไปแล้วก่อนเขียน DB) — เช็คผลด้วย เดิมทิ้ง return ทิ้งเลย
    -- เช็ค InvCanCarry ไปแล้วข้างบน เคสนี้จึงเหลือแค่ของหลุด (ตัวละครหลุดกลางทาง/inventory ล่ม)
    -- ถ้าให้ของไม่ได้ต้องคืนเงิน + คืน listing ให้ขายต่อได้ ไม่ใช่กินทั้งเงินทั้งของ
    if not InvAddItem(src, listing.item_name, buyQty) then
        refundBuyer('เพิ่มไอเทมเข้ากระเป๋าไม่ได้')
        if buyQty == listing.quantity then
            MySQL.update.await(
                'UPDATE lp_marketplace SET status=?,buyer_id=NULL,buyer_name=NULL,sold_at=NULL WHERE id=? AND status=?',
                { 'active', listingId, 'sold' })
        else
            MySQL.update.await('UPDATE lp_marketplace SET quantity=quantity+? WHERE id=? AND status=?',
                { buyQty, listingId, 'active' })
            -- ลบแถว sold ที่เพิ่ง INSERT ไป ไม่งั้นผู้ขาย claim เงินของดีลที่ล้มได้
            MySQL.update.await(
                'DELETE FROM lp_marketplace WHERE seller_id=? AND buyer_id=? AND item_name=? AND quantity=? AND price=? AND status=? ORDER BY id DESC LIMIT 1',
                { listing.seller_id, buyerCharId, listing.item_name, buyQty, listing.price, 'sold' })
        end
        Log('buy', '⚠️ ซื้อล้ม', ('คืนเงิน+คืนประกาศ id %s ให้ charid %s'):format(
            tostring(listingId), tostring(buyerCharId)))
        Notify(src, Config.Locale.buy_fail)
        return
    end

    Notify(src, Config.Locale.buy_success, 'success')
    TriggerClientEvent('lp_marketplace:refreshBuy', src)

    Log('buy', '💰 ซื้อสินค้า',
        ('**%s** ซื้อ **%s** x%d จาก **%s** ราคา %d (%s) ภาษี %d'):format(
            GetPlayerName(src), listing.item_label, buyQty,
            listing.seller_name, totalPrice, listing.currency, tax))
    return true
end

RegisterServerEvent('lp_marketplace:buyItem')
AddEventHandler('lp_marketplace:buyItem', function(listingId, buyQty)
    DoBuy(source, listingId, buyQty)
end)

-- ── ดึงรายการของฉัน (SELL tab) ────────────────────────────────────────────────
RegisterServerEvent('lp_marketplace:getMyListings')
AddEventHandler('lp_marketplace:getMyListings', function()
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    local rows = MySQL.query.await(
        'SELECT id,item_name,item_label,category,quantity,price,currency,expires_at FROM lp_marketplace WHERE seller_id=? AND status=? ORDER BY created_at DESC',
        { Character.charIdentifier, 'active' })

    TriggerClientEvent('lp_marketplace:receiveMyListings', src, rows or {})
end)

-- ── ยกเลิกการขาย ──────────────────────────────────────────────────────────────
RegisterServerEvent('lp_marketplace:cancelListing')
AddEventHandler('lp_marketplace:cancelListing', function(listingId)
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    listingId = tonumber(listingId)
    if not listingId then return end
    if not CheckCooldown(cancelCooldowns, src, COOLDOWN_CANCEL) then return end

    local listing = MySQL.single.await(
        'SELECT id,item_name,item_label,quantity FROM lp_marketplace WHERE id=? AND seller_id=? AND status=? LIMIT 1',
        { listingId, Character.charIdentifier, 'active' })

    if not listing then
        Notify(src, Config.Locale.cancel_fail)
        return
    end

    MySQL.update.await('UPDATE lp_marketplace SET status=? WHERE id=?', { 'cancelled', listingId })
    InvAddItem(src, listing.item_name, listing.quantity)

    Notify(src, Config.Locale.cancel_success, 'success')
    TriggerClientEvent('lp_marketplace:refreshSell', src)

    Log('cancel', '❌ ยกเลิกขาย',
        ('**%s** ยกเลิกขาย **%s** x%d'):format(GetPlayerName(src), listing.item_label, listing.quantity))
end)

-- ── ดึงรายการ ITEM tab (sold / expired) ───────────────────────────────────────
RegisterServerEvent('lp_marketplace:getItemClaims')
AddEventHandler('lp_marketplace:getItemClaims', function()
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    local rows = MySQL.query.await(
        'SELECT id,item_name,item_label,category,quantity,price,currency,status FROM lp_marketplace WHERE seller_id=? AND status IN (?,?) ORDER BY created_at DESC',
        { Character.charIdentifier, 'sold', 'expired' })

    -- แนบยอดที่จะได้รับจริงไปเลย ให้ NUI แค่เอาไปแสดง ไม่ต้องรู้สูตรภาษี — ตัวเลขที่ผู้เล่นเห็น
    -- จึงมาจากฟังก์ชันเดียวกับที่ claimItem ใช้จ่ายเงินจริง โอกาสโชว์ไม่ตรงกับที่ได้จึงเป็นศูนย์
    for _, row in ipairs(rows or {}) do
        if row.status == 'sold' then
            row.payout, row.tax = CalcPayout(row.price, row.quantity)
        end
    end

    TriggerClientEvent('lp_marketplace:receiveItemClaims', src, rows or {})
end)

-- ── รับเงิน / รับของคืน (ITEM tab claim) ─────────────────────────────────────
RegisterServerEvent('lp_marketplace:claimItem')
AddEventHandler('lp_marketplace:claimItem', function(listingId)
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    listingId = tonumber(listingId)
    if not listingId then return end
    if not CheckCooldown(claimCooldowns, src, COOLDOWN_CLAIM) then return end

    local listing = MySQL.single.await(
        'SELECT id,item_name,item_label,quantity,price,currency,status FROM lp_marketplace WHERE id=? AND seller_id=? AND status IN (?,?) LIMIT 1',
        { listingId, Character.charIdentifier, 'sold', 'expired' })

    if not listing then
        Notify(src, Config.Locale.claim_fail)
        return
    end

    if listing.status == 'sold' then
        -- คิดจากราคารวม (price × quantity) ไม่ใช่ราคาต่อชิ้น
        local net, tax = CalcPayout(listing.price, listing.quantity)
        Character.addCurrency(CurrencyType(listing.currency), net)
        Log('claim', '💵 รับเงิน',
            ('**%s** รับ **%d** %s (หลังภาษี %d)'):format(GetPlayerName(src), net, listing.currency, tax))
    else
        InvAddItem(src, listing.item_name, listing.quantity)
        Log('claim', '📦 รับของคืน (หมดอายุ)',
            ('**%s** รับ **%s** x%d คืน'):format(GetPlayerName(src), listing.item_label, listing.quantity))
    end

    MySQL.update.await('DELETE FROM lp_marketplace WHERE id=?', { listingId })

    Notify(src, Config.Locale.claim_success, 'success')
    TriggerClientEvent('lp_marketplace:refreshItem', src)
end)

-- ── ดึง inventory ผู้เล่น (inventory picker popup) ────────────────────────────
local invCooldowns = {}
RegisterServerEvent('lp_marketplace:getInventory')
AddEventHandler('lp_marketplace:getInventory', function()
    local src       = source
    local Character = GetCharacter(src)
    if not Character then return end

    if not CheckCooldown(invCooldowns, src, 2) then return end

    local items = InvGetAll(src)
    local inventory = {}
    for _, item in ipairs(items or {}) do
        local qty = item.count or 0
        if qty > 0 then
            inventory[#inventory+1] = { name = item.name, label = item.label, count = qty,
                                        category = GetCategoryForItem(item.name), group = item.group }
        end
    end
    TriggerClientEvent('lp_marketplace:receiveInventory', src, inventory)
end)

-- ── Cleanup cooldown tables (ทุก 10 นาที) ────────────────────────────────────
CreateThread(function()
    while true do
        Wait(600000)
        local now = os.time()
        for _, tbl in ipairs({ buyCooldowns, cancelCooldowns, claimCooldowns, invCooldowns, listingsCooldowns }) do
            for src, t in pairs(tbl) do
                if now - t > 60 then tbl[src] = nil end
            end
        end
    end
end)
