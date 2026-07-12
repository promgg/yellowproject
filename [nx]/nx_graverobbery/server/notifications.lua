NX_GR = NX_GR or {}
NX_GR.Alerts = {}

local function hasJob(character, jobs)
    return NX_GR.TableContains(jobs, character.job)
end

local function hasRole(character, roles)
    return NX_GR.TableContains(roles, character.group)
end

local function isRecipient(entry, mode, settings)
    if mode == 'all_village_members' then return true end
    if mode == 'jobs' then return hasJob(entry.character, settings.jobs) end
    if mode == 'village_roles' then return hasRole(entry.character, settings.roles) end
    return false
end

function NX_GR.Alerts.Dispatch(grave)
    local village = Config.Villages[grave.villageId]
    if not village or not village.notification or not village.notification.enabled then return end
    if grave.notification and grave.notification.enabled == false then return end

    local settings = village.notification
    if math.random(1, 100) > (settings.alertChance or 0) then return end

    local recipients = {}
    if settings.recipientMode == 'custom' and type(Config.CustomAlertRecipients) == 'function' then
        recipients = Config.CustomAlertRecipients({ grave = grave, village = village }) or {}
    else
        for _, entry in ipairs(NX_GR.CitySelect.GetOnlinePlayersInVillage(grave.villageId)) do
            if isRecipient(entry, settings.recipientMode, settings) then
                recipients[#recipients + 1] = entry.source
            end
        end
    end

    if #recipients == 0 then return end

    local delayMin = settings.alertDelayMin or 0
    local delayMax = settings.alertDelayMax or delayMin
    local delay = math.random(delayMin, delayMax) * 1000

    SetTimeout(delay, function()
        local payload = {
            graveId = grave.id,
            villageId = grave.villageId,
            coords = { x = grave.coords.x, y = grave.coords.y, z = grave.coords.z },
            blipDuration = settings.blipDuration or 60,
            routeEnabled = settings.routeEnabled == true,
        }

        for _, target in ipairs(recipients) do
            TriggerClientEvent('nx_graverobbery:client:receiveAlert', target, payload)
        end
    end)
end
