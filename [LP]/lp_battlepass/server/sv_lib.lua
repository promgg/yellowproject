-- lp_battlepass — array diff helper (ใช้ใน claimAllReward เพื่อหาเลเวลที่ยังไม่เคลม)
BPArray = {}

-- คืนสมาชิกใน list1 ที่ไม่มีใน list2 (list เป็น array ของ int)
BPArray.diff = function(list1, list2)
    local hash = {}
    for i = 1, #list2 do hash[list2[i]] = true end
    local out = {}
    for i = 1, #list1 do
        if not hash[list1[i]] then out[#out + 1] = list1[i] end
    end
    return out
end

-- แปลง CSV string ("0,3,5") เป็น array ของ int
BPArray.split = function(str)
    local out = {}
    if not str or str == '' then return out end
    for token in tostring(str):gmatch('([^,]+)') do
        local n = tonumber(token)
        if n then out[#out + 1] = n end
    end
    return out
end
