NX_GR = NX_GR or {}

local function getLocaleTable()
    local locale = Config.Locale or 'th'
    return Locales[locale] or Locales.en or {}
end

function NX_GR.Locale(key, vars)
    local value = getLocaleTable()[key] or (Locales.en and Locales.en[key]) or key
    if vars then
        for name, replacement in pairs(vars) do
            -- gsub เห็น pattern แรกเป็น Lua pattern (% เป็นตัว escape) ต้องใช้ %% ถึงจะแมตช์ % ตัวจริงในข้อความ (%{amount})
            -- ส่วน replacement (%1) ก็ต้อง escape % ทับด้วย ป้องกันค่าที่แทนมีเครื่องหมาย % ปนอยู่
            local pattern = ('%%%%{%s}'):format(name)
            local safeReplacement = tostring(replacement):gsub('%%', '%%%%')
            value = value:gsub(pattern, safeReplacement)
        end
    end
    return value
end
