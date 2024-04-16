local Table = require('__stdlib__/stdlib/utils/table')

Sites = {}

---@alias IntPosition {x: integer, y: integer}
---@alias DirectionIdentifier 'top'|'bottom'|'left'|'right'
---@alias SiteChunk {x: integer, y: integer, top: integer, bottom: integer, left: integer, right: integer}
---@alias Site {type: string, name: string, surface: integer, chunks: SiteChunk[], amount: integer, initial_amount: integer, positions: IntPosition[], index: integer, since: integer}

---@alias GlobalSites {surfaces: table<integer, table<string, Site[]?>?>?}
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
                type = resource.name,
                name = get_random_name(pos),
                surface = surface.index,
                chunks = {},
                amount = 0,
                initial_amount = 0,
                positions = {},
                since = game.tick,
                index = 0,
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

function Sites.reset_cache()
    global.sites = {}
end

---Add a new site to the cache
---@param site Site
function Sites.add_site_to_cache(site)
    if not global.sites then
        global.sites = { surfaces = {} }
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

    local outer_chunks = get_outer_chunks(site)

    game.print('add: ' .. site.name .. ' ' .. site.type)

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

    -- we did not return yet, so we simply add it now
    local index = #global.sites.surfaces[site.surface][site.type] + 1
    site.index = index
    global.sites.surfaces[site.surface][site.type][index] = site
end

---@param sites Site[]
function Sites.add_sites_to_cache(sites)
    for key, site in pairs(sites) do
        Sites.add_site_to_cache(site)
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
end

function Sites.update_cached_all()
    if global.sites == nil then return nil end
    for surfaceKey, surfaces in pairs(Sites.get_sites_from_cache_all()) do
        for type, sites in pairs(surfaces) do
            for index, site in pairs(sites) do
                Sites.update_cached_site(site)
            end
        end
    end
end

script.on_nth_tick(180, function(event) Sites.update_cached_all() end) -- todo adjust
