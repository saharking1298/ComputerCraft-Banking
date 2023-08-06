local utils = { _version = "1.0.0" }
function utils.SplitString (text, sep)
    if sep == nil then
            sep = "%s"
    end
    local t = {}
    for str in string.gmatch(text, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

return utils
