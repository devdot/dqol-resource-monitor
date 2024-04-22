local Naming = {}

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
