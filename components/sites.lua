local Table = require('__stdlib__/stdlib/utils/table')

Sites = {}

---@alias IntPosition {x: integer, y: integer}
---@alias DirectionIdentifier 'top'|'bottom'|'left'|'right'
---@alias SiteChunk {x: integer, y: integer, top: integer, bottom: integer, left: integer, right: integer}
---@alias SiteArea {left: integer, right: integer, top: integer, bottom: integer, x: integer, y: integer}
---@alias Site {id: integer, type: string, name: string, surface: integer, chunks: SiteChunk[], amount: integer, initial_amount: integer, positions: IntPosition[], index: integer, since: integer, area: SiteArea, tracking: boolean, map_tag: LuaCustomChartTag?}

---@alias GlobalSites {surfaces: table<integer, table<string, Site[]?>?>?, ids: table<integer, Site>?}
---@cast global {sites: GlobalSites?}

local names = {
    'Julia',
    'Midderfield',
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
}

---@param pos IntPosition
---@return string
local function pos_to_compass_direction(pos)
    local direction
    if pos.y < 0 then direction = 'N' else direction = 'S' end
    if pos.x > 0 then direction = direction .. 'E' else direction = direction .. 'W' end
    return direction
end

---@param pos IntPosition?
---@return string
local function get_random_name(pos)
    local name = names[math.random(1, #names)]
    if pos ~= nil then
       name = pos_to_compass_direction(pos) .. ' ' .. name 
    end
    return name
end

---@param name string
---@return SignalID
local function get_signal_id(name)
    local type = 'item'
    if name == 'crude-oil' then type = 'fluid' end
    return {
        type = type,
        name = name,
    }
end

---@param border integer
---@param xBase integer
---@param yBase integer
---@param surface integer
local function helper_highligh_chunk_border_lr(border, xBase, yBase, surface, color)
    local x = xBase
    for i = 0, 31, 1 do
        if bit32.band(border, bit32.lshift(1, i)) > 0 then
            local y = yBase + i
            rendering.draw_rectangle {
                color = color,
                filled = true,
                left_top = { x = x, y = y },
                right_bottom = { x = x + 1, y = y + 1 },
                surface = surface,
                time_to_live = 200,
                draw_on_ground = true,
            }
        end
    end
end

---@param border integer
---@param xBase integer
---@param yBase integer
---@param surface integer
local function helper_highligh_chunk_border_tb(border, xBase, yBase, surface, color)
    local y = yBase
    for i = 0, 31, 1 do
        if bit32.band(border, bit32.lshift(1, i)) > 0 then
            local x = xBase + i
            rendering.draw_rectangle {
                color = color,
                filled = true,
                left_top = { x = x, y = y },
                right_bottom = { x = x + 1, y = y + 1 },
                surface = surface,
                time_to_live = 200,
                draw_on_ground = true,
            }
        end
    end
end

---@param chunk SiteChunk
---@param surface integer
local function helper_highligh_chunk_border_left(chunk, surface)
    helper_highligh_chunk_border_lr(chunk.left, chunk.x * 32, chunk.y * 32, surface, { r = 255, g = 128, b = 0 })
end

---@param chunk SiteChunk
---@param surface integer
local function helper_highligh_chunk_border_right(chunk, surface)
    helper_highligh_chunk_border_lr(chunk.right, ((chunk.x + 1) * 32) - 1, chunk.y * 32, surface,
        { r = 255, g = 0, b = 128 })
end

---@param chunk SiteChunk
---@param surface integer
local function helper_highligh_chunk_border_top(chunk, surface)
    helper_highligh_chunk_border_tb(chunk.top, chunk.x * 32, chunk.y * 32, surface, { r = 255, g = 64, b = 0 })
end

---@param chunk SiteChunk
---@param surface integer
local function helper_highligh_chunk_border_bottom(chunk, surface)
    helper_highligh_chunk_border_tb(chunk.bottom, chunk.x * 32, ((chunk.y + 1) * 32) - 1, surface,
        { r = 255, g = 0, b = 64 })
end

---Highlight a given chunk in the game world
---@param site Site
function Sites.highlight_site(site)
    local color = {
        r = 0,
        g = math.random(0, 255),
        b = math.random(128, 255),
    }

    rendering.draw_rectangle {
        color = color,
        left_top = { x = site.area.left, y = site.area.top },
        right_bottom = { x = site.area.right + 1, y = site.area.bottom + 1},
        surface = site.surface,
        time_to_live = 200,
    }

    rendering.draw_circle {
        color = {r = 255, g = 0, b = 0},
        radius = 1,
        target = { x = site.area.x + 0.5, y = site.area.y + 0.5 },
        surface = site.surface,
        time_to_live = 200,
    }

    for key, pos in pairs(site.positions) do
        rendering.draw_rectangle {
            color = color,
            filled = true,
            left_top = pos,
            right_bottom = { x = pos.x + 1, y = pos.y + 1 },
            surface = site.surface,
            time_to_live = 200,
            draw_on_ground = true,
        }
    end

    for key, chunk in pairs(site.chunks) do
        if chunk.left > 0 then
            helper_highligh_chunk_border_left(chunk, site.surface)
        end

        if chunk.right > 0 then
            helper_highligh_chunk_border_right(chunk, site.surface)
        end

        if chunk.top > 0 then
            helper_highligh_chunk_border_top(chunk, site.surface)
        end

        if chunk.bottom > 0 then
            helper_highligh_chunk_border_bottom(chunk, site.surface)
        end
    end
end

---Calculate outer chunks
---@param site Site
---@return string[]
local function get_outer_chunks(site)
    local outer_chunks = {}
    for key, chunk in pairs(site.chunks) do
        if chunk.bottom > 0 or chunk.top > 0 or chunk.left > 0 or chunk.right > 0 then
            table.insert(outer_chunks, key)
        end
    end
    return outer_chunks
end

---Calculate the keys to the chunks that are neighboring this chun
---@param chunk SiteChunk
---@return table<string, {direction: DirectionIdentifier, opposite: DirectionIdentifier}>
local function get_neighboring_chunk_keys(chunk)
    local neighbors = {}
    if chunk.top > 0 then
        neighbors[chunk.x .. ',' .. chunk.y - 1] = { direction = 'top', opposite = 'bottom' }
    end
    if chunk.bottom > 0 then
        neighbors[chunk.x .. ',' .. chunk.y + 1] = { direction = 'bottom', opposite = 'top' }
    end
    if chunk.left > 0 then
        neighbors[chunk.x - 1 .. ',' .. chunk.y] = { direction = 'left', opposite = 'right' }
    end
    if chunk.right > 0 then
        neighbors[chunk.x + 1 .. ',' .. chunk.y] = { direction = 'right', opposite = 'left' }
    end
    return neighbors
end

---@param site SiteArea
---@return SiteArea
local function update_site_area_center(site)
    site.x = site.left + math.floor((site.right - site.left) / 2)
    site.y = site.top + math.floor((site.bottom - site.top) / 2)
    return site
end

---@param areaBase SiteArea
---@param areaAdd SiteArea
---@return SiteArea
local function merge_site_areas(areaBase, areaAdd)
    if areaAdd.top < areaBase.top then areaBase.top = areaAdd.top end
    if areaAdd.bottom > areaBase.bottom then areaBase.bottom = areaAdd.bottom end
    if areaAdd.left < areaBase.left then areaBase.left = areaAdd.left end
    if areaAdd.right > areaBase.right then areaBase.right = areaAdd.right end
    return update_site_area_center(areaBase)
end

---Merge a site into another one. Returns the first param with the second merged into it
---@param siteBase Site
---@param siteAdd Site
---@return Site
local function merge_sites(siteBase, siteAdd)
    siteBase.amount = siteBase.amount + siteAdd.amount
    siteBase.initial_amount = siteBase.initial_amount + siteAdd.initial_amount
    siteBase.chunks = Table.dictionary_combine(siteBase.chunks, siteAdd.chunks)
    siteBase.positions = Table.array_combine(siteBase.positions, siteAdd.positions)
    siteBase.since = math.min(siteBase.since, siteAdd.since)
    siteBase.area = merge_site_areas(siteBase.area, siteAdd.area)
    return siteBase
end

---@param resources LuaResource[]
---@param surface LuaSurface
---@param chunk ChunkPositionAndArea
---@return Site[]
function Sites.create_from_chunk_resources(resources, surface, chunk)
    ---@type Site[]
    local types = {}
    local chunk_key = chunk.x .. ',' .. chunk.y

    for key, resource in pairs(resources) do
        local pos = {
            x = math.floor(resource.position.x),
            y = math.floor(resource.position.y),
        }

        if not types[resource.name] then
            types[resource.name] = {
                id = 0,
                type = resource.name,
                name = get_random_name(pos),
                surface = surface.index,
                chunks = {},
                amount = 0,
                initial_amount = 0,
                positions = {},
                since = game.tick,
                index = 0,
                area = { top = pos.y, bottom = pos.y, left = pos.x, right = pos.x },
                tracking = true, -- todo create a default setting for this
            }

            types[resource.name].chunks[chunk_key] = {
                x = chunk.x,
                y = chunk.y,
                top = 0,
                bottom = 0,
                left = 0,
                right = 0,
            }
        end

        table.insert(types[resource.name].positions, pos)
        types[resource.name].amount = types[resource.name].amount + resource.amount
        types[resource.name].initial_amount = types[resource.name].initial_amount +
            (resource.initial_amount or resource.amount)

        local modX = pos.x % 32
        local modY = pos.y % 32

        if modX == 0 then
            types[resource.name].chunks[chunk_key].left = bit32.bor(types[resource.name].chunks[chunk_key].left,
                bit32.lshift(1, modY))
        elseif modX == 31 then
            types[resource.name].chunks[chunk_key].right = bit32.bor(types[resource.name].chunks[chunk_key].right,
                bit32.lshift(1, modY))
        end

        if modY == 0 then
            types[resource.name].chunks[chunk_key].top = bit32.bor(types[resource.name].chunks[chunk_key].top,
                bit32.lshift(1, modX))
        elseif modY == 31 then
            types[resource.name].chunks[chunk_key].bottom = bit32.bor(types[resource.name].chunks[chunk_key].bottom,
                bit32.lshift(1, modX))
        end
    end

    return types
end

---@param site Site
---@return Site
function Sites.update_site_area(site)
    for key, pos in pairs(site.positions) do
        if pos.x > site.area.right then
            site.area.right = pos.x
        elseif pos.x < site.area.left then
            site.area.left = pos.x
        end

        if pos.y > site.area.bottom then
            site.area.bottom = pos.y
        elseif pos.y < site.area.top then
            site.area.top = pos.y
        end
    end
    site.area = update_site_area_center(site.area)
    return site
end

function Sites.reset_cache()
    global.sites = {}
    global.ids = {}
end

---Add a new site to the cache
---@param site Site
function Sites.add_site_to_cache(site)
    if not global.sites then
        global.sites = { surfaces = {} }
    end

    if not global.sites.ids then
        global.sites.ids = {}
    end

    if not global.sites.surfaces then
        global.sites.surfaces = {}
    end

    if not global.sites.surfaces[site.surface] then
        global.sites.surfaces[site.surface] = {}
    end

    if not global.sites.surfaces[site.surface][site.type] then
        global.sites.surfaces[site.surface][site.type] = {}
    end

    site = Sites.update_site_area(site)
    local outer_chunks = get_outer_chunks(site)

    -- now check if this borders any other sites
    for _, chunkKey in pairs(outer_chunks) do
        -- calculate the relevant neighbors first
        local neighborKeys = get_neighboring_chunk_keys(site.chunks[chunkKey])

        for neighborKey, d in pairs(neighborKeys) do
            local direction = d.direction
            local otherDirection = d.opposite
            for siteKey, otherSite in pairs(global.sites.surfaces[site.surface][site.type]) do
                if otherSite.chunks[neighborKey] ~= nil then
                    -- now check if they actually match up
                    if bit32.band(site.chunks[chunkKey][direction], otherSite.chunks[neighborKey][otherDirection]) > 0 then
                        if _DEBUG then
                            game.print('Merge into site ' .. otherSite.name)
                        end

                        -- we found a match
                        -- clean up the seam
                        site.chunks[chunkKey][direction] = 0
                        otherSite.chunks[neighborKey][otherDirection] = 0
                        -- merge into here
                        global.sites.surfaces[site.surface][site.type][siteKey] = merge_sites(otherSite, site)
                        return
                    end
                end
            end
        end
    end
    
    if _DEBUG then
        game.print('Add new site ' .. site.name)
    end

    -- we did not return yet, so we simply add it now
    local index = #global.sites.surfaces[site.surface][site.type] + 1
    site.index = index
    global.sites.surfaces[site.surface][site.type][index] = site

    -- add to ids
    local nextId = #(global.sites.ids) + 1
    site.id = nextId
    global.sites.ids[nextId] = site
end

---@param sites Site[]
function Sites.add_sites_to_cache(sites)
    for key, site in pairs(sites) do
        Sites.add_site_to_cache(site)
    end
end

function Sites.update_site_map_tag(site)
    if settings.global['external-dashboard-site-map-markers'].value == true then
        local text = site.name .. ' ' .. Ui.int_to_exponent_string(site.amount)
        if site.map_tag == nil then
            site.map_tag = game.forces[Scanner.DEFAULT_FORCE].add_chart_tag(site.surface, {
                position = site.area,
                text = text,
                icon = get_signal_id(site.type),
            })
        else
            site.map_tag.text = text
        end
    else
        -- remove if the tag exists
        if site.map_tag ~= nil then
            site.map_tag.destroy()
            site.map_tag = nil
        end
    end
end

---@param surface_index integer
---@return table<string, Site[]?>
function Sites.get_sites_from_cache(surface_index)
    if global.sites == nil then return {} end
    if global.sites.surfaces == nil then return {} end
    return global.sites.surfaces[surface_index] or {}
end

---@return table<integer, table<string, Site[]?>>
function Sites.get_sites_from_cache_all()
    if global.sites == nil then return {} end
    return global.sites.surfaces or {}
end

---@param surface_index integer
---@param type string
---@param index integer
---@return Site?
function Sites.get_site_from_cache(surface_index, type, index)
    if global.sites == nil then return nil end
    if global.sites.surfaces == nil then return nil end
    if global.sites.surfaces[surface_index] == nil then return nil end
    if global.sites.surfaces[surface_index][type] == nil then return nil end
    return global.sites.surfaces[surface_index][type][index] or nil
end

---Get site from cache using ID
---@param id integer
---@return Site?
function Sites.get_site_by_id(id)
    if global.sites == nil then return nil end
    if global.sites.ids == nil then return nil end
    return global.sites.ids[id] or nil;
end

---@param site Site
function Sites.update_cached_site(site)
    local amount = 0
    local surface = game.surfaces[site.surface]
    for key, pos in pairs(site.positions) do
        local resource = surface.find_entity(site.type, {pos.x + 0.5, pos.y + 0.5})
        if resource and resource.amount > 0 then
            amount = amount + resource.amount
        else
            table.remove(site.positions, key)
        end
    end

    site.amount = amount

    Sites.update_site_map_tag(site)
end

function Sites.update_cached_all()
    -- todo: implement partial update
    -- when external-dashboard-site-entities-per-update is not 0
    if global.sites == nil then return nil end
    for surfaceKey, surfaces in pairs(Sites.get_sites_from_cache_all()) do
        for type, sites in pairs(surfaces) do
            for index, site in pairs(sites) do
                Sites.update_cached_site(site)
            end
        end
    end
end

function Sites.boot()
    script.on_nth_tick(settings.global['external-dashboard-site-ticks-between-updates'].value, function(event) Sites.update_cached_all() end) -- todo adjust
end

