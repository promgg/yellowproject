NX_GR = NX_GR or {}

local function getLocaleTable()
    local locale = Config.Locale or 'th'
    return Locales[locale] or Locales.en or {}
end

function NX_GR.Locale(key, vars)
    local value = getLocaleTable()[key] or (Locales.en and Locales.en[key]) or key
    if vars then
        for name, replacement in pairs(vars) do
            value = value:gsub(('%%{%s}'):format(name), tostring(replacement))
        end
    end
    return value
end
