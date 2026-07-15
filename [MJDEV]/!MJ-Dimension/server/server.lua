local script = '!MJ-Dimension'
RegisterNetEvent('MJ-dimension:changeBucket', function(bucketId)
    local src = source
    SetPlayerRoutingBucket(src, tonumber(bucketId))
    currentBucket = bucketId
end)

RegisterNetEvent('MJ-dimension:resetBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
    currentBucket = 0
end)


if GetCurrentResourceName() ~= script then
    os.exit()
end