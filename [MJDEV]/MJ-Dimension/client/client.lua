local zoneid = 0
local currentBucket = nil
local Locations = {}
CreateThread(function()
    for k=1, #Config.dimensionZones do
        Locations[k] = PolyZone:Create(Config.dimensionZones[k].zones, {
            name = "SearchLocation"..k,
            minZ = Config.dimensionZones[k].minz,
            maxZ = Config.dimensionZones[k].maxz,
            debugGrid = Config.dimensionZones[k].debugGrid,
            gridDivisions = Config.dimensionZones[k].gridDivisions,
        })
        Locations[k]:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
            local source = source
            if isPointInside then
                zoneid = k
                local bucketId = Config.dimensionZones[k].dimensionId
                TriggerServerEvent('MJ-dimension:changeBucket', bucketId)
                if Config.dimensionNotify then
                    Notify({
                        text = Locale('change_dimension', {bucketId = bucketId}),
                        time = 4000,
                        type = "success"
                    })
                end
            elseif zoneid == k then
                zoneid = nil
                TriggerServerEvent('MJ-dimension:resetBucket') 
                if Config.dimensionNotify then
                    Notify({
                        text = Locale('default_dimension'),
                        time = 4000,
                        type = "success"
                    })
                end
            end
        end)
    end
end)