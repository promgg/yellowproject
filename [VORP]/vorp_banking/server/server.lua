local VORPcore = exports.vorp_core:GetCore()
local T = Translation.Langs[Config.Lang]

local function registerStorage(bankName, bankId, invspace)
    local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(bankId)
    if not isRegistered then
        local data = {
            id = bankId,
            name = bankName,
            limit = invspace,
            acceptWeapons = Config.banks[bankName].canStoreWeapons,
            shared = true,
            ignoreItemStackLimit = true,
            webhook = Config.CustomInventoryWebhook, -- add here your webhook url for discord logging
        }
        exports.vorp_inventory:registerInventory(data)
        Wait(200)
    end
end

local function IsNearBank(source, bankName)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local bankLocation = Config.banks[bankName].BankLocation
    local distance = #(playerCoords - vector3(bankLocation.x, bankLocation.y, bankLocation.z))

    if distance <= Config.banks[bankName].distOpen + 10.0 then -- Adjusted Distance check to make sure it's within range (if any bank is facing issue then you can increase this value)
        return true
    else
        return false
    end
end

-- true ถ้าตู้เซฟ/อัปเกรดช่องของธนาคารนี้ใช้ได้กับผู้เล่นคนนี้ (ไม่ล็อกเมือง หรือ nx_cityselect ไม่ทำงาน = อนุญาตเสมอ)
local function isOwnCityBank(_source, bankName)
    if not Config.SafeBox.lockToOwnCity then return true end
    if not VORP_BANK.CitySelect.IsNxCitySelectActive() then return true end

    local playerCity = VORP_BANK.CitySelect.GetPlayerCityId(_source)
    if not playerCity then return false end

    return playerCity:lower() == (bankName or ""):lower()
end

-- ── Anti-spam: คูลดาวน์ต่อ source ต่อชนิด event (กันยิงถี่/สคริปต์กด dupe) ──
local txCooldown = {} -- [source][eventName] = GetGameTimer() ครั้งล่าสุด
local function onCooldown(_source, eventName)
    local now = GetGameTimer()
    local bucket = txCooldown[_source]
    if not bucket then
        txCooldown[_source] = { [eventName] = now }
        return false
    end
    local last = bucket[eventName]
    if last and (now - last) < Config.TxCooldownMs then
        return true
    end
    bucket[eventName] = now
    return false
end

-- console audit trail — ไม่ผูกกับ webhook (webhook default ว่าง จึงต้องมี log พื้นฐานเสมอ)
local function logTx(charid, action, detail)
    print(("[vorp_banking] char=%s %s %s"):format(tostring(charid), action, detail or ""))
end

-- คืน Character ถ้ามีจริง + bankName ถูกต้อง ไม่งั้นคืน nil (trust boundary: อย่าเชื่อ bankName จาก client)
local function resolveRequest(_source, bankName)
    if not bankName or not Config.banks[bankName] then return nil end
    local user = VORPcore.getUser(_source)
    if not user then return nil end
    local Character = user.getUsedCharacter
    if not Character then return nil end
    return Character
end

-- amount ต้องเป็นตัวเลขบวกจริงเท่านั้น (กันติดลบ/0/NaN/inf ที่ทำให้ removeCurrency กลับด้านเป็นปั๊มเงิน)
local function isValidAmount(amount)
    amount = tonumber(amount)
    if not amount or amount ~= amount then return nil end -- nil หรือ NaN
    if amount <= 0 or amount == math.huge then return nil end
    return amount
end

VORPcore.Callback.Register('vorp_bank:getinfo', function(source, cb, bankName)
    local _source = source
    local Character = resolveRequest(_source, bankName)
    if not Character then return cb({ {}, {} }) end -- ฝั่ง client เช็ค `if not bankinfo.money` แล้วปิดเมนูเอง

    local charidentifier = Character.charIdentifier
    local identifier = Character.identifier
    local isOwnCity = isOwnCityBank(_source, bankName)

    -- คอลัมน์เจาะจง ไม่ใช้ SELECT * (ตารางมี items longtext ก้อนใหญ่ที่เมนูไม่ได้ใช้)
    local row = MySQL.query.await("SELECT money, gold, invspace FROM bank_users WHERE charidentifier = @charidentifier AND name = @bankName LIMIT 1",
        { charidentifier = charidentifier, bankName = bankName })

    if not (row and row[1]) then
        -- ยังไม่มีบัญชีธนาคารนี้ -> สร้างด้วยค่าเริ่มต้น
        MySQL.insert.await("INSERT INTO bank_users (`name`,`identifier`,`charidentifier`,`money`,`gold`,`invspace`) VALUES (@name, @identifier, @charidentifier, @money, @gold, @invspace)", {
            name = bankName, identifier = identifier, charidentifier = charidentifier,
            money = 0, gold = 0, invspace = Config.SafeBox.defaultInvspace
        })
        row = { { money = 0, gold = 0, invspace = Config.SafeBox.defaultInvspace } }
    end

    local bankinfo = { money = row[1].money, gold = row[1].gold, invspace = row[1].invspace, name = bankName, isOwnCity = isOwnCity }
    local allBanks = MySQL.query.await("SELECT name, money FROM bank_users WHERE charidentifier = @charidentifier", { charidentifier = charidentifier }) or {}

    return cb({ bankinfo, allBanks })
end)

-- source ที่กำลังมี upgrade request ค้างอยู่ (กัน double-submit ระหว่างรอ MySQL.scalar ตอบ)
local upgradeInProgress = {}

RegisterServerEvent('vorp_bank:UpgradeSafeBox', function(slotsToBuy, bankName)
    local _source = source
    local Character = resolveRequest(_source, bankName)
    if not Character then return end
    local bankCfg = Config.banks[bankName]

    if upgradeInProgress[_source] then
        return Notify({ source = _source, text = T.upgradeBusy or "Please wait...", time = 4000, type = "error" })
    end

    -- ต้องเป็นจำนวนเต็มบวกเท่านั้น กัน slotsToBuy ติดลบ/ทศนิยม/0 ที่ทำให้ amountToPay ติดลบ (ปั๊มเงิน)
    slotsToBuy = tonumber(slotsToBuy)
    if not slotsToBuy or slotsToBuy <= 0 or slotsToBuy ~= math.floor(slotsToBuy) then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if not isOwnCityBank(_source, bankName) then
        return Notify({ source = _source, text = T.wrongCity or "This safe box is locked to your home city.", time = 4000, type = "error" })
    end

    local charidentifier = Character.charIdentifier
    local maxslots        = bankCfg.maxslots
    local costslot        = bankCfg.costslot
    local name            = bankCfg.city

    upgradeInProgress[_source] = true

    -- ค่าช่องปัจจุบันต้อง query จาก DB เอง ห้ามเชื่อค่าที่ client ส่งมา (เดิมรับ currentspace ตรงๆ จาก client
    -- ทำให้ปลอมค่าแล้วจ่ายแค่ 1 ช่องแต่ได้ช่องกระโดดไปเกือบเต็มได้)
    -- concurrent ของ source เดียวกันถูกกันด้วย upgradeInProgress; row นี้ผูกต่อตัวละคร source อื่นแตะไม่ได้
    local currentspace = MySQL.scalar.await('SELECT `invspace` FROM `bank_users` WHERE `charidentifier` = @charidentifier AND `name` = @name LIMIT 1', {
        charidentifier = charidentifier, name = name
    })
    if not currentspace then
        upgradeInProgress[_source] = nil
        return Notify({ source = _source, text = T.invOpenFail, time = 4000, type = "error" })
    end

    local money       = Character.money -- อ่านสดตอนนี้ ไม่ใช้ค่าที่ capture ไว้ก่อนรอ query
    local amountToPay = costslot * slotsToBuy
    local FinalSlots  = currentspace + slotsToBuy

    if money < amountToPay then
        upgradeInProgress[_source] = nil
        return Notify({ source = _source, text = T.nomoney, time = 4000, type = "error" })
    end

    if FinalSlots > maxslots then
        upgradeInProgress[_source] = nil
        return Notify({ source = _source, text = T.maxslots .. " | " .. slotsToBuy .. " / " .. maxslots, time = 4000, type = "error" })
    end

    if FinalSlots < Config.SafeBox.minSlots then
        upgradeInProgress[_source] = nil
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    -- เขียน DB ก่อน แล้วเช็คผลสำเร็จ ค่อยหักเงิน — ถ้า DB เขียนไม่ผ่านจะไม่มีการหักเงิน (กันเสียเงินฟรี)
    local affected = MySQL.update.await("UPDATE bank_users SET invspace=@invspace WHERE charidentifier=@charidentifier AND name = @name", {
        charidentifier = charidentifier, invspace = FinalSlots, name = name
    })
    if not affected or affected == 0 then
        upgradeInProgress[_source] = nil
        return Notify({ source = _source, text = T.invOpenFail, time = 4000, type = "error" })
    end

    Character.removeCurrency(0, amountToPay)
    local bankId = "vorp_banking_" .. bankName .. "_" .. charidentifier
    registerStorage(bankName, bankId, currentspace)
    exports.vorp_inventory:updateCustomInventorySlots(bankId, FinalSlots)
    Notify({ source = _source, text = T.success .. amountToPay .. " | " .. FinalSlots .. " / " .. maxslots, time = 4000, type = "success" })
    logTx(charidentifier, "upgrade_safebox", ("bank=%s +%d slot(s) $%d -> %d/%d"):format(bankName, slotsToBuy, amountToPay, FinalSlots, maxslots))

    upgradeInProgress[_source] = nil
end)

DiscordLogs = function(transactionAmount, bankName, playerName, transactionType, targetBankName, currencyType, itemName)
    local logTitle = T.Webhooks.LogTitle
    local webhookURL, logMessage = "", ""
    local currencySymbol = currencyType == "gold" and "G" or "$"

    if transactionType == "withdraw" then
        webhookURL = Config.WithdrawLogWebhook
        logMessage = string.format(T.Webhooks.WithdrawLogDescription, playerName, transactionAmount .. currencySymbol, bankName)
    elseif transactionType == "deposit" then
        webhookURL = Config.DepositLogWebhook
        logMessage = string.format(T.Webhooks.DepositLogDescription, playerName, transactionAmount .. currencySymbol, bankName)
    elseif transactionType == "transfer" then
        webhookURL = Config.TransferLogWebhook
        logMessage = string.format(T.Webhooks.TransferLogDescription, playerName, transactionAmount .. currencySymbol, bankName, targetBankName)
    elseif transactionType == "take" then
        webhookURL = Config.TakeLogWebhook
        logMessage = string.format(T.Webhooks.TakeLogDescription, playerName, transactionAmount, itemName, bankName)
    elseif transactionType == "move" then
        webhookURL = Config.MoveLogWebhook
        logMessage = string.format(T.Webhooks.MoveLogDescription, playerName, transactionAmount, itemName, bankName)
    end

    VORPcore.AddWebhook(logTitle, webhookURL, logMessage)
end

RegisterServerEvent('vorp_bank:transfer', function(amount, fromBank, toBank)
    local _source = source
    -- ต้องมีบัญชีทั้งต้นทาง+ปลายทางจริงในคอนฟิก และห้ามโอนเข้าบัญชีเดียวกัน (กันวนสร้างเงินจากค่าธรรมเนียมกลับด้าน)
    local Character = resolveRequest(_source, fromBank)
    if not Character or not Config.banks[toBank] or fromBank == toBank then return end

    amount = isValidAmount(amount)
    if not amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, toBank) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if onCooldown(_source, 'transfer') then return end

    local characterId = Character.charIdentifier
    local playerFullName = Character.firstname .. ' ' .. Character.lastname
    local credited = amount * Config.feeamount -- ปลายทางได้หลังหักค่าธรรมเนียม

    -- หักบัญชีต้นทางแบบ atomic (เงื่อนไข money >= amount อยู่ในตัว UPDATE เอง ไม่มีช่อง race)
    local debited = MySQL.update.await("UPDATE bank_users SET money = money - @amount WHERE charidentifier = @characterId AND name = @fromBank AND money >= @amount", {
        amount = amount, characterId = characterId, fromBank = fromBank
    })
    if not debited or debited == 0 then
        return Notify({ source = _source, text = T.noaccmoney, time = 4000, type = "error" })
    end

    -- เข้าบัญชีปลายทาง; ถ้าไม่สำเร็จ (เช่น ยังไม่มี row บัญชีปลายทาง) rollback คืนต้นทางเต็มจำนวน
    local funded = MySQL.update.await("UPDATE bank_users SET money = money + @credited WHERE charidentifier = @characterId AND name = @toBank", {
        credited = credited, characterId = characterId, toBank = toBank
    })
    if not funded or funded == 0 then
        MySQL.update.await("UPDATE bank_users SET money = money + @amount WHERE charidentifier = @characterId AND name = @fromBank", {
            amount = amount, characterId = characterId, fromBank = fromBank
        })
        logTx(characterId, "transfer_rollback", ("%s->%s $%.2f (dest update failed, refunded)"):format(fromBank, toBank, amount))
        return Notify({ source = _source, text = T.noaccmoney, time = 4000, type = "error" })
    end

    local transferredAmount = string.format("%.2f", credited)
    DiscordLogs(transferredAmount, fromBank, playerFullName, "transfer", toBank, "cash")
    logTx(characterId, "transfer", ("%s->%s debit $%.2f credit $%s"):format(fromBank, toBank, amount, transferredAmount))
    local msg = string.format(T.transfer .. "%s $" .. T.to .. "%s" .. T.transferred, transferredAmount, toBank)
    Notify({ source = _source, text = msg, time = 4000, type = "success" })
end)

RegisterServerEvent('vorp_bank:depositcash', function(amount, bankName)
    local _source = source
    local playerCharacter = resolveRequest(_source, bankName)
    if not playerCharacter then return end

    amount = isValidAmount(amount)
    if not amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if onCooldown(_source, 'depositcash') then return end

    local characterId = playerCharacter.charIdentifier
    if playerCharacter.money < amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    -- หักเงินสดผู้เล่นก่อน (ยอดสด authoritative จาก character object) แล้วเพิ่มยอดธนาคารแบบ atomic
    playerCharacter.removeCurrency(0, amount)
    local affected = MySQL.update.await("UPDATE bank_users SET money = money + @amount WHERE charidentifier = @characterId AND name = @bankName", {
        characterId = characterId, amount = amount, bankName = bankName
    })
    if not affected or affected == 0 then
        playerCharacter.addCurrency(0, amount) -- rollback: ไม่มี row บัญชี ธนาคารนี้ คืนเงินสดผู้เล่น
        return Notify({ source = _source, text = T.invOpenFail, time = 4000, type = "error" })
    end

    DiscordLogs(amount, bankName, playerCharacter.firstname .. ' ' .. playerCharacter.lastname, "deposit", "cash")
    logTx(characterId, "deposit_cash", ("bank=%s $%s"):format(bankName, amount))
    Notify({ source = _source, text = T.youdepo .. amount, time = 4000, type = "success" })
end)

RegisterServerEvent('vorp_bank:depositgold', function(amount, bankName)
    local _source = source
    local playerCharacter = resolveRequest(_source, bankName)
    if not playerCharacter then return end

    amount = isValidAmount(amount)
    if not amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if onCooldown(_source, 'depositgold') then return end

    local characterId = playerCharacter.charIdentifier
    if playerCharacter.gold < amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    playerCharacter.removeCurrency(1, amount)
    local affected = MySQL.update.await("UPDATE bank_users SET gold = gold + @amount WHERE charidentifier = @characterId AND name = @bankName", {
        characterId = characterId, amount = amount, bankName = bankName
    })
    if not affected or affected == 0 then
        playerCharacter.addCurrency(1, amount) -- rollback
        return Notify({ source = _source, text = T.invOpenFail, time = 4000, type = "error" })
    end

    logTx(characterId, "deposit_gold", ("bank=%s G%s"):format(bankName, amount))
    Notify({ source = _source, text = T.youdepog .. amount, time = 4000, type = "success" })
end)


RegisterServerEvent('vorp_bank:withcash', function(amount, bankName)
    local _source = source
    local Character = resolveRequest(_source, bankName)
    if not Character then return end

    amount = isValidAmount(amount)
    if not amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if onCooldown(_source, 'withcash') then return end

    local characterId = Character.charIdentifier
    -- หักยอดธนาคารแบบ atomic (money >= amount อยู่ในเงื่อนไข UPDATE) — กัน race/double-click ที่เคยต้องพึ่ง lastMoney hack
    local affected = MySQL.update.await("UPDATE bank_users SET money = money - @amount WHERE charidentifier = @characterId AND name = @bankName AND money >= @amount", {
        characterId = characterId, amount = amount, bankName = bankName
    })
    if not affected or affected == 0 then
        return Notify({ source = _source, text = T.invalid .. amount, time = 4000, type = "error" })
    end

    Character.addCurrency(0, amount)
    DiscordLogs(amount, bankName, Character.firstname .. ' ' .. Character.lastname, "withdraw", "cash")
    logTx(characterId, "withdraw_cash", ("bank=%s $%s"):format(bankName, amount))
    Notify({ source = _source, text = T.withdrew .. amount, time = 4000, type = "success" })
end)

RegisterServerEvent('vorp_bank:withgold', function(amount, bankName)
    local _source = source
    local playerCharacter = resolveRequest(_source, bankName)
    if not playerCharacter then return end

    amount = isValidAmount(amount)
    if not amount then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if onCooldown(_source, 'withgold') then return end

    local characterId = playerCharacter.charIdentifier
    local affected = MySQL.update.await("UPDATE bank_users SET gold = gold - @amount WHERE charidentifier = @characterId AND name = @bankName AND gold >= @amount", {
        characterId = characterId, amount = amount, bankName = bankName
    })
    if not affected or affected == 0 then
        return Notify({ source = _source, text = T.invalid, time = 4000, type = "error" })
    end

    playerCharacter.addCurrency(1, amount)
    DiscordLogs(amount, bankName, playerCharacter.firstname .. ' ' .. playerCharacter.lastname, "withdraw", "gold")
    logTx(characterId, "withdraw_gold", ("bank=%s G%s"):format(bankName, amount))
    Notify({ source = _source, text = T.withdrewg .. amount, time = 4000, type = "success" })
end)


RegisterServerEvent("vorp_banking:server:OpenBankInventory", function(bankName)
    local _source = source
    local Character = resolveRequest(_source, bankName)
    if not Character then return end

    local characterId = Character.charIdentifier
    local bankId = "vorp_banking_" .. bankName .. "_" .. characterId

    if not IsNearBank(_source, bankName) then
        return Notify({ source = _source, text = T.notnear, time = 4000, type = "error" })
    end

    if not isOwnCityBank(_source, bankName) then
        return Notify({ source = _source, text = T.wrongCity or "This safe box is locked to your home city.", time = 4000, type = "error" })
    end

    if onCooldown(_source, 'openbox') then return end

    -- Check database for invSpace server side.
    MySQL.scalar('SELECT `invspace` FROM `bank_users` WHERE `charidentifier` = @characterId AND `name` = @bankName LIMIT 1', {
        characterId = characterId, bankName = bankName
    }, function(invSpace)
        if invSpace then
            registerStorage(bankName, bankId, invSpace)
            exports.vorp_inventory:openInventory(_source, bankId)
        else
            Notify({ source = _source, text = T.invOpenFail, time = 4000, type = "error" })
        end
    end)
end)

AddEventHandler("playerDropped", function()
    local _source = source
    txCooldown[_source] = nil
    upgradeInProgress[_source] = nil
end)
