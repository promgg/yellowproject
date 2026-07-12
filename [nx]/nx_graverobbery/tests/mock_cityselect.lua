local MockCity = {}

function MockCity.getVillage(player)
    return player and player.village or nil
end

function MockCity.getRecipients(players, villageId, roles)
    local recipients = {}
    for source, player in pairs(players) do
        if player.village == villageId then
            for _, role in ipairs(roles) do
                if player.role == role then
                    recipients[#recipients + 1] = source
                end
            end
        end
    end
    table.sort(recipients)
    return recipients
end

return MockCity
