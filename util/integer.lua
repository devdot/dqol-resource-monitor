local integer = {}

---@param ticks integer
---@param default string?
---@return string
function integer.toTimeString(ticks, default)
    if ticks == nil then
        return default or '0:00:00'
    end

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
    while integer >= 1000 do
        integer = integer / 1000
        i = i + 1
    end
    return string.format((i > 1 and '%.2f') or '%d', integer) .. SI_STRINGS[i]
end

---@param integer integer
---@param precision integer?
---@return string
function integer.toPercent(integer, precision)
    if precision == nil then precision = 0 end
    return string.format('%.' .. precision .. 'f', integer * 100) .. '%'
end

---@param integer integer
---@return {r: integer, g: integer, b: integer}
function integer.toColor(integer)
    return {
        r = (1 - integer) * 255,
        g = integer * 255,
        b = 0,
    }
end

return integer
