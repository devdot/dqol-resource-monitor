local integer = {}

---@param ticks integer
---@return string
function integer.toTimeString(ticks)
    local sec = math.floor(ticks / 60)
    local min = math.floor(sec / 60)
    local hour = math.floor(min / 60)
    min = (min % 60)
    sec = (sec % 60)
    if min < 10 then min = '0' .. min end
    if sec < 10 then sec = '0' .. sec end
    return hour .. ':' .. min .. ':' .. sec
end

local SI_STRINGS = {'', 'k', 'M', 'G', 'T', 'P', 'E', 'Z'}

---@param integer integer
---@return string
function integer.toExponentString(integer)
    local i = 1
    while integer > 100 do
        integer = integer / 1000
        i = i + 1
    end
    return string.format('%.2f', integer) .. SI_STRINGS[i]
end

return integer
