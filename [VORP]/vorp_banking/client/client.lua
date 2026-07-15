local VORPcore = exports.vorp_core:GetCore()
local inmenu = false
local T = Translation.Langs[Config.Lang]
local MenuData = exports.vorp_menu:GetMenuData()

-- ธนาคารที่กำลังโชว์ floating prompt/TextUI อยู่ตอนนี้ (โชว์ได้ทีละอันเดียว)
local activeBank = nil
local activeBankMode = nil -- 'open' | 'closed'
local currentBankName = nil
local currentBankInfo = nil
local currentAllBanks = nil
local TEXTUI_RELEASE_DELAY = 350

local function suppressTextUI(state, releaseDelayMs)
    if GetResourceState("lp_textui") == "started" then
        exports.lp_textui:SetSuppressed(state, releaseDelayMs or 0)
    end
end

local function clearActivePrompt()
    if activeBank then
        exports.lp_textui:CancelHold()
        exports.lp_textui:HideUI()
    end
    activeBank = nil
    activeBankMode = nil
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, v in pairs(Config.banks) do
            if v.BlipHandle then
                RemoveBlip(v.BlipHandle)
            end
            if v.NPC then
                DeleteEntity(v.NPC)
                DeletePed(v.NPC)
                SetEntityAsNoLongerNeeded(v.NPC)
            end
        end
        clearActivePrompt()
        suppressTextUI(false, 0)
        DisplayRadar(true)
        MenuData.CloseAll()
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "close" })
        ClearPedTasks(PlayerPedId(), true, true)
    end
end)

---------------- BLIPS ---------------------
local function addBlip(index)
    if Config.banks[index].blipAllowed then
        local blip = BlipAddForCoords(1664425300, Config.banks[index].BankLocation.x, Config.banks[index].BankLocation.y, Config.banks[index].BankLocation.z)
        SetBlipSprite(blip, Config.banks[index].blipsprite, true)
        SetBlipScale(blip, 0.2)
        SetBlipName(blip, Config.banks[index].name)
        Config.banks[index].BlipHandle = blip
    end
end

---------------- NPC ---------------------
local function loadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model, false)
        repeat Wait(0) until HasModelLoaded(model)
    end
end

local function spawnNPC(index)
    local v = Config.banks[index]
    loadModel(v.NpcModel)
    local npc = CreatePed(joaat(v.NpcModel), v.NpcPosition.x, v.NpcPosition.y, v.NpcPosition.z, v.NpcPosition.h, false, false, false, false)
    repeat Wait(0) until DoesEntityExist(npc)
    PlaceEntityOnGroundProperly(npc, true)
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
    SetEntityCanBeDamaged(npc, false)
    SetEntityInvincible(npc, true)
    Wait(1000)
    TaskStandStill(npc, -1)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(v.NpcModel)
    Config.banks[index].NPC = npc
end

local function getDistance(config)
    local coords = GetEntityCoords(PlayerPedId())
    local coords2 = vector3(config.x, config.y, config.z)
    return #(coords - coords2)
end

local function createNpcByDistance(distance, index)
    if Config.banks[index].NpcAllowed then
        if distance <= 40 then
            if not Config.banks[index].NPC then
                spawnNPC(index)
            end
        else
            if Config.banks[index].NPC then
                SetEntityAsNoLongerNeeded(Config.banks[index].NPC)
                DeleteEntity(Config.banks[index].NPC)
                Config.banks[index].NPC = nil
            end
        end
    end
end

local function getBankInfo(bankConfig)
    suppressTextUI(true)
    local result = VORPcore.Callback.TriggerAwait("vorp_bank:getinfo", bankConfig.city) or {}
    Openbank(bankConfig.city, result[1] or {}, result[2] or {}, result[3] or {})
    TaskStandStill(PlayerPedId(), -1)
    DisplayRadar(false)
end

local function bankAnchor(bankConfig)
    return {
        coords = vector3(bankConfig.BankLocation.x, bankConfig.BankLocation.y, bankConfig.BankLocation.z),
        offset = vector3(0.0, 0.0, 0.5),
    }
end

-- ตั้ง/สลับ floating prompt ให้ตรงกับธนาคารที่ใกล้ที่สุดตอนนี้ (มีได้ทีละอันเดียว)
local function updateActivePrompt(index, bankConfig, closed)
    local mode = closed and 'closed' or 'open'
    if activeBank == index and activeBankMode == mode then
        return -- อันเดิม ไม่ต้องเรียกซ้ำ
    end

    clearActivePrompt()
    activeBank = index
    activeBankMode = mode

    if closed then
        local msg = ("%s %s%s - %s%s"):format(T.openHours, bankConfig.StoreOpen, T.amTimeZone, bankConfig.StoreClose, T.pmTimeZone)
        local shown = exports.lp_textui:TextUI(msg, nil, bankAnchor(bankConfig))
        if shown == false then
            activeBank = nil
            activeBankMode = nil
        end
    else
        local msg = ("[E] %s %s"):format(T.bank, bankConfig.name)
        local shown = exports.lp_textui:TextUIHold(msg, Config.HoldMs, function()
            inmenu = true
            getBankInfo(bankConfig)
            clearActivePrompt()
        end, Config.Key, bankAnchor(bankConfig))
        if shown == false then
            activeBank = nil
            activeBankMode = nil
        end
    end
end

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession

    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local dead = IsEntityDead(player)
        local nearestIndex, nearestBankConfig, nearestClosed = nil, nil, nil

        if not inmenu and not dead then
            for index, bankConfig in pairs(Config.banks) do
                if bankConfig.StoreHoursAllowed then
                    local hour = GetClockHours()
                    if hour >= bankConfig.StoreClose or hour < bankConfig.StoreOpen then
                        if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                            addBlip(index)
                        end

                        if Config.banks[index].BlipHandle then
                            BlipAddModifier(Config.banks[index].BlipHandle, joaat('BLIP_MODIFIER_MP_COLOR_10'))
                        end

                        if Config.banks[index].NPC then
                            DeleteEntity(Config.banks[index].NPC)
                            DeletePed(Config.banks[index].NPC)
                            SetEntityAsNoLongerNeeded(Config.banks[index].NPC)
                            Config.banks[index].NPC = nil
                        end

                        local distance = getDistance(bankConfig.BankLocation)

                        if distance <= bankConfig.distOpen and not nearestIndex then
                            sleep = 0
                            nearestIndex, nearestBankConfig, nearestClosed = index, bankConfig, true
                        end
                    elseif hour >= bankConfig.StoreOpen then
                        if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                            addBlip(index)
                        end

                        if Config.banks[index].BlipHandle then
                            BlipAddModifier(Config.banks[index].BlipHandle, joaat('BLIP_MODIFIER_MP_COLOR_32'))
                        end

                        local distance = getDistance(bankConfig.BankLocation)
                        createNpcByDistance(distance, index)
                        if distance <= bankConfig.distOpen and not nearestIndex then
                            sleep = 0
                            nearestIndex, nearestBankConfig, nearestClosed = index, bankConfig, false
                        end
                    end
                else
                    local distance = getDistance(bankConfig.BankLocation)
                    if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                        addBlip(index)
                    end

                    createNpcByDistance(distance, index)

                    if distance <= bankConfig.distOpen and not nearestIndex then
                        sleep = 0
                        nearestIndex, nearestBankConfig, nearestClosed = index, bankConfig, false
                    end
                end
            end
        end

        if not nearestIndex then
            clearActivePrompt()
        else
            updateActivePrompt(nearestIndex, nearestBankConfig, nearestClosed)
        end

        Wait(sleep)
    end
end)

local function closeMenu()
    MenuData.CloseAll()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    inmenu = false
    currentBankName = nil
    currentBankInfo = nil
    currentAllBanks = nil
    ClearPedTasks(PlayerPedId())
    DisplayRadar(true)
    suppressTextUI(false, TEXTUI_RELEASE_DELAY)
end

local function notifyInvalid()
    Notify({ text = T.invalid, time = 4000, type = "error" })
end

local function validPositiveNumber(value, integerOnly)
    local amount = tonumber(value)
    if not amount or amount ~= amount or amount == math.huge or amount <= 0 then
        return nil
    end

    if integerOnly then
        amount = math.floor(amount)
        if amount < 1 then return nil end
    end

    return amount
end

local function makeAccountId(bankName, charidentifier)
    local code = tostring(bankName or "BK"):gsub("[^%w]", ""):upper():sub(1, 2)
    if code == "" then code = "BK" end
    return ("%s-1849-%s"):format(code, tostring(charidentifier or GetPlayerServerId(PlayerId())))
end

local function transferBankPayload(bankName, allbanks)
    local result = {}

    for _, bank in ipairs(allbanks or {}) do
        if bank.name and bank.name ~= bankName and Config.banks[bank.name] then
            result[#result + 1] = {
                name = bank.name,
                label = Config.banks[bank.name].name or bank.name,
                money = tonumber(bank.money) or 0,
            }
        end
    end

    return result
end

function Openbank(bankName, bankinfo, allbanks, playerinfo)
    MenuData.CloseAll()
    if not bankinfo.money then
        closeMenu()
        return
    end

    local bankConfig = Config.banks[bankName]
    local ownCity = bankinfo.isOwnCity ~= false
    local transfers = transferBankPayload(bankName, allbanks)

    currentBankName = bankName
    currentBankInfo = bankinfo
    currentAllBanks = allbanks
    inmenu = true

    suppressTextUI(true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        bank = {
            name = bankName,
            displayName = "ธนาคาร " .. (bankConfig.city or bankName),
            subtitle = (bankConfig.city or bankName) .. " Savings & Trust",
            hours = bankConfig.StoreHoursAllowed and
                (("เปิดทำการ %02d:00-%02d:00"):format(bankConfig.StoreOpen, bankConfig.StoreClose)) or
                "เปิดทำการ 24 ชั่วโมง",
        },
        account = {
            accountId = makeAccountId(bankName, playerinfo.charidentifier),
            money = tonumber(bankinfo.money) or 0,
            gold = tonumber(bankinfo.gold) or 0,
            invspace = tonumber(bankinfo.invspace) or 0,
        },
        player = {
            id = GetPlayerServerId(PlayerId()),
            money = tonumber(playerinfo.money) or 0,
            gold = tonumber(playerinfo.gold) or 0,
            name = ((playerinfo.firstname or "") .. " " .. (playerinfo.lastname or "")):gsub("^%s*(.-)%s*$", "%1"),
        },
        capabilities = {
            gold = bankConfig.gold == true,
            locker = bankConfig.items == true and ownCity,
            upgrade = bankConfig.upgrade == true and ownCity,
            transfer = Config.banktransfer == true and #transfers > 0,
            costSlot = tonumber(bankConfig.costslot) or 0,
            maxSlots = tonumber(bankConfig.maxslots) or 0,
        },
        transferBanks = transfers,
    })
end

RegisterNUICallback("close", function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback("transaction", function(data, cb)
    if not currentBankName or not currentBankInfo then
        return cb({ ok = false, error = "bank session unavailable" })
    end

    local direction = data and tostring(data.direction or "") or ""
    local currency = data and tostring(data.currency or "") or ""
    local amount = validPositiveNumber(data and data.amount, false)
    local bankConfig = Config.banks[currentBankName]

    if not amount or (direction ~= "deposit" and direction ~= "withdraw") or
        (currency ~= "cash" and currency ~= "gold") or (currency == "gold" and not bankConfig.gold) then
        notifyInvalid()
        return cb({ ok = false, error = T.invalid })
    end

    local events = {
        deposit = { cash = "vorp_bank:depositcash", gold = "vorp_bank:depositgold" },
        withdraw = { cash = "vorp_bank:withcash", gold = "vorp_bank:withgold" },
    }
    local eventName = events[direction][currency]
    local bankName = currentBankName
    closeMenu()
    TriggerServerEvent(eventName, amount, bankName)
    cb({ ok = true })
end)

RegisterNUICallback("openLocker", function(_, cb)
    if not currentBankName or not currentBankInfo then
        return cb({ ok = false, error = "bank session unavailable" })
    end

    local bankConfig = Config.banks[currentBankName]
    if bankConfig.items ~= true or currentBankInfo.isOwnCity == false or (tonumber(currentBankInfo.invspace) or 0) <= 0 then
        Notify({ text = "You need to buy locker slots first", time = 4000, type = "error" })
        return cb({ ok = false, error = "กรุณาอัปเกรดพื้นที่ล็อคเกอร์ก่อน" })
    end

    local bankName = currentBankName
    closeMenu()
    TriggerServerEvent("vorp_banking:server:OpenBankInventory", bankName)
    cb({ ok = true })
end)

RegisterNUICallback("upgradeLocker", function(data, cb)
    if not currentBankName or not currentBankInfo then
        return cb({ ok = false, error = "bank session unavailable" })
    end

    local slots = validPositiveNumber(data and data.slots, true)
    local bankConfig = Config.banks[currentBankName]
    if not slots or bankConfig.upgrade ~= true or currentBankInfo.isOwnCity == false then
        notifyInvalid()
        return cb({ ok = false, error = T.invalid })
    end

    local bankName = currentBankName
    closeMenu()
    TriggerServerEvent("vorp_bank:UpgradeSafeBox", slots, bankName)
    cb({ ok = true })
end)

RegisterNUICallback("transfer", function(data, cb)
    if not currentBankName or not currentAllBanks or Config.banktransfer ~= true then
        return cb({ ok = false, error = "bank session unavailable" })
    end

    local amount = validPositiveNumber(data and data.amount, false)
    local fromBank = data and tostring(data.fromBank or "") or ""
    local allowed = false

    for _, bank in ipairs(currentAllBanks) do
        if bank.name == fromBank and fromBank ~= currentBankName and Config.banks[fromBank] then
            allowed = true
            break
        end
    end

    if not amount or not allowed then
        notifyInvalid()
        return cb({ ok = false, error = T.invalid })
    end

    local toBank = currentBankName
    closeMenu()
    TriggerServerEvent("vorp_bank:transfer", amount, fromBank, toBank)
    cb({ ok = true })
end)
