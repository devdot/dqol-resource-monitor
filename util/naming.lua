local Naming = {}

---@param pos IntPosition?
---@param type string
---@return string
function Naming.getSiteName(pos, type)
    local generator = settings.global['dqol-resource-monitor-site-name-generator'].value
    if generator == 'Numeric' then
        return Naming.getNumericName(type)
    elseif generator == 'Custom' then
        return Naming.getCustomName(pos, type)
    else
        return Naming.getRandomName(pos)
    end
end

---@param pos IntPosition?
---@return string
function Naming.getRandomName(pos)
    local name = Naming.names[math.random(1, #Naming.names)]

    -- 2/3 chance to have an adjective in front
    if math.random(1, 3) ~= 3 then
        name = Naming.adjectives[math.random(1, #Naming.adjectives)] .. ' ' .. name
    end

    -- 1/4 cache to have a double name
    if math.random(1, 4) == 1 then
        name = name .. ' ' .. Naming.names[math.random(1, #Naming.names)]
    end

    if pos ~= nil then
       name = Naming.posToCompassDirection(pos) .. ' ' .. name 
    end
    return name
end

local function get_next_index_for_type(type)
    local index = 1
    for _, surface in pairs(Sites.storage.getSurfaceList()) do
        index = index + #(surface[type] or {})
    end

    return index
end

---@param site Site
local function get_index_for_site(site)
    local index = 0

    for surfaceId, surface in pairs(Sites.storage.getSurfaceList()) do
        if surfaceId < site.surface then
            index = index + #(surface[type] or {})
        elseif surfaceId == site.surface then
            return index + site.index
        else
            return index
        end
    end

    return index

end

---@param type string
---@return string
function Naming.getNumericName(type)
    return Resources.types[type].translated_name .. ' ' .. get_next_index_for_type(type)
end

---@param pos IntPosition?
---@param type string
---@param site ?Site
---@return string
function Naming.getCustomName(pos, type, site)
    local name = settings.global['dqol-resource-monitor-site-name-generator-custom-pattern'].value or ''
    
    if string.match(name, '%%id%%') then
        local nextId = (site and site.id) or (#(Sites.storage.getIdList()) + 1)
        name = string.gsub(name, '%%id%%', nextId)
    end

    if string.match(name, '%%index%%') then
        name = string.gsub(name, '%%index%%', (site and get_index_for_site(site)) or get_next_index_for_type(type))
    end

    if string.match(name, '%%compass%%') then
        name = string.gsub(name, '%%compass%%', Naming.posToCompassDirection(pos))
    end

    if string.match(name, '%%icon%%') then
        name = string.gsub(name, '%%icon%%', Resources.getIconString(type))
    end

    -- simple replaces
    name = string.gsub(name, '%%type%%', Resources.types[type].translated_name)
    
    return name
end

---@param pos IntPosition
---@return string
function Naming.posToCompassDirection(pos)
    local direction
    if pos.y < 0 then direction = 'N' else direction = 'S' end
    if pos.x > 0 then direction = direction .. 'E' else direction = direction .. 'W' end
    return direction
end

Naming.names = {
    'Julia',
    'Mandeep',
    'Enni',
    'Nastya',
    'Judith',
    'Yenny',
    'Chiyembekezo',
    'Yuuri',
    'Cornelia',
    'Tionge',
    'Kanda',
    'Rosa',
    'Gisila',
    'Peppi ',
    'Amara',
    'Kaleigh',
    'Zoe',
    'Josephine',
    'Tiara',
    'Gia',
    'Julianne',
    'Leila',
    'Amari',
    'Daisy',
    'Daniella',
    'Raquel',
    'Westray',
    'Carningsby',
    'Doveport',
    'Sanlow',
    'Hillford',
    'Aberystwyth',
    'Thorpeness',
    'Malrton',
    'Ely',
    'Cirencester',
    'Astrakhan',
    'Balerno',
    'Willowdale',
    'Fallkirk',
    'Bournemouth',
    'Taernsby',
    'Willsden',
    'Axminster',
    'Cardended',
    'Onryx',
    'Lerwick',
    'Eastborne',
    'Gramsby',
    'Laenteglos',
    'Alnerwick',
    'Stanmore',
    'Inverness',
    'Beachmarsh',
    'Murrayfield',
}

Naming.adjectives = {
    'Little',
    'New',
    'Old',
    'Red',
    'Dark',
    'Ancient',
    'Boring',
    'Bustling',
    'Charming',
    'Compact',
    'Crowded',
    'Famous',
    'Fantastic',
    'Historic',
    'Huge',
    'Polluted',
    'Quiet',
    'Rich',
    'Stupid',
    'Tiny',
    'Victorious',
}

return Naming
