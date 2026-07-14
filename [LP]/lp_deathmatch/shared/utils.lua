LP_DM = LP_DM or {}

function LP_DM.TableContains(list, value)
    if type(list) ~= 'table' then return false end
    for _, item in ipairs(list) do
        if item == value then return true end
    end
    return false
end

function LP_DM.Distance(a, b)
    local ax, ay, az = a.x or a[1], a.y or a[2], a.z or a[3]
    local bx, by, bz = b.x or b[1], b.y or b[2], b.z or b[3]
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

function LP_DM.SafeResourceStarted(name)
    return GetResourceState and GetResourceState(name) == 'started'
end
