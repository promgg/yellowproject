LP_DM = LP_DM or {}

local function getLocaleTable()
    local locale = Config.Locale or 'th'
    return Locales[locale] or Locales.en or {}
end

function LP_DM.Locale(key, vars)
    local value = getLocaleTable()[key] or (Locales.en and Locales.en[key]) or key
    if vars then
        for name, replacement in pairs(vars) do
            -- gsub เห็น pattern แรกเป็น Lua pattern (% เป็นตัว escape) ต้องใช้ %% ถึงจะแมตช์ % ตัวจริงในข้อความ (%{amount})
            local pattern = ('%%%%{%s}'):format(name)
            local safeReplacement = tostring(replacement):gsub('%%', '%%%%')
            value = value:gsub(pattern, safeReplacement)
        end
    end
    return value
end
