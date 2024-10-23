-- from stdlib (not updated to 2.0 for now)
-- https://github.com/Afforess/Factorio-Stdlib/blob/master/stdlib/utils/table.lua
local function dictionary_combine(...)
    local tables = { ... }
    local new = {}
    for _, tab in pairs(tables) do for k, v in pairs(tab) do new[k] = v end end
    return new
end

Sites = {
    storage = {},
    site = {},
    updater = {},
}

---@alias IntPosition {x: integer, y: integer}
---@alias DirectionIdentifier 'top'|'bottom'|'left'|'right'
---@alias SiteChunkKey string A special format key, encoding the chunk position
---@alias SiteChunkBorders {left: integer, right: integer, top: integer, bottom: integer}
---@alias SiteChunk {x: integer, y: integer, tiles: integer, amount: integer, updated: integer, borders: SiteChunkBorders}
---@alias SiteArea {left: integer, right: integer, top: integer, bottom: integer, x: integer, y: integer}
---@alias SiteCalculated {updated_at: integer, amount: integer, percent: number, rate: number, estimated_depletion: integer?, last_amount: integer, last_amount_tick: integer}
---@alias Site {id: integer, calculated: SiteCalculated, type: string, name: string, surface: integer, chunks: table<SiteChunkKey, SiteChunk>, initial_amount: integer, index: integer, since: integer, area: SiteArea, tracking: boolean, map_tag: LuaCustomChartTag?}

---@alias GlobalSitesUpdater {pointer: integer, queue: table<integer, table<1|2, integer|SiteChunkKey>>} -- queue sub-entries simply have 1: siteId and 2: chunkId
---@alias GlobalSites {surfaces: table<integer, table<string, Site[]?>?>?, ids: table<integer, Site>?, updater: GlobalSitesUpdater}

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

---Highlight a given site in the game world
---@param site Site
function Sites.site.highlight(site)
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

    -- show chunk borders for debug
    if _DEBUG ~= true then return end
    for key, chunk in pairs(site.chunks) do
        if chunk.borders.left > 0 then
            helper_highligh_chunk_border_lr(chunk.borders.left, chunk.x * 32, chunk.y * 32, site.surface, { r = 255, g = 128, b = 0 })
        end

        if chunk.borders.right > 0 then
            helper_highligh_chunk_border_lr(chunk.borders.right, ((chunk.x + 1) * 32) - 1, chunk.y * 32, site.surface, { r = 255, g = 0, b = 128 })
        end

        if chunk.borders.top > 0 then
            helper_highligh_chunk_border_tb(chunk.borders.top, chunk.x * 32, chunk.y * 32, site.surface, { r = 255, g = 64, b = 0 })
        end

        if chunk.borders.bottom > 0 then
            helper_highligh_chunk_border_tb(chunk.borders.bottom, chunk.x * 32, ((chunk.y + 1) * 32) - 1, site.surface, { r = 255, g = 0, b = 64 })
        end
    end
end

---Calculate outer chunks
---@param site Site
---@return SiteChunkKey[]
local function get_outer_chunks(site)
    local outer_chunks = {}
    for key, chunk in pairs(site.chunks) do
        if chunk.borders.bottom > 0 or chunk.borders.top > 0 or chunk.borders.left > 0 or chunk.borders.right > 0 then
            table.insert(outer_chunks, key)
        end
    end
    return outer_chunks
end

---Calculate the keys to the chunks that are neighboring this chun
---@param chunk SiteChunk
---@param getAll boolean?
---@return table<SiteChunkKey, {direction: DirectionIdentifier, opposite: DirectionIdentifier, diagonal: nil|'left'|'right'}>
local function get_neighboring_chunk_keys(chunk, getAll)
    local neighbors = {}
    -- directly neighboring
    if getAll or chunk.borders.top > 0 then
        neighbors[chunk.x .. ',' .. chunk.y - 1] = { direction = 'top', opposite = 'bottom' }
    end
    if getAll or chunk.borders.bottom > 0 then
        neighbors[chunk.x .. ',' .. chunk.y + 1] = { direction = 'bottom', opposite = 'top' }
    end
    if getAll or chunk.borders.left > 0 then
        neighbors[chunk.x - 1 .. ',' .. chunk.y] = { direction = 'left', opposite = 'right' }
    end
    if getAll or chunk.borders.right > 0 then
        neighbors[chunk.x + 1 .. ',' .. chunk.y] = { direction = 'right', opposite = 'left' }
    end

    -- diagonal corners
    if getAll or bit32.band(chunk.borders.top, 1) then
        neighbors[chunk.x - 1 .. ',' .. chunk.y - 1] = { direction = 'top', opposite = 'bottom', diagonal = 'left' }
    end
    if getAll or bit32.band(chunk.borders.top, 2147483648) then
        neighbors[chunk.x + 1 .. ',' .. chunk.y - 1] = { direction = 'top', opposite = 'bottom', diagonal = 'right' }
    end
    if getAll or bit32.band(chunk.borders.bottom, 1) then
        neighbors[chunk.x - 1 .. ',' .. chunk.y - 1] = { direction = 'bottom', opposite = 'top', diagonal = 'left' }
    end
    if getAll or bit32.band(chunk.borders.bottom, 2147483648) then
        neighbors[chunk.x + 1 .. ',' .. chunk.y - 1] = { direction = 'bottom', opposite = 'top', diagonal = 'right' }
    end
    return neighbors
end

---@param area SiteArea
---@return SiteArea
local function update_site_area_center(area)
    area.x = area.left + math.floor((area.right - area.left) / 2)
    area.y = area.top + math.floor((area.bottom - area.top) / 2)
    return area
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
    siteBase.initial_amount = siteBase.initial_amount + siteAdd.initial_amount
    siteBase.chunks = dictionary_combine(siteBase.chunks, siteAdd.chunks)
    siteBase.since = math.min(siteBase.since, siteAdd.since)
    siteBase.area = merge_site_areas(siteBase.area, siteAdd.area)
    Sites.site.updateCalculated(siteBase)
    return siteBase
end

---@param resources LuaEntity[]
---@param surface LuaSurface
---@param chunk ChunkPositionAndArea
function Sites.createFromChunkResources(resources, surface, chunk)
    ---@type Site[]
    local types = {}
    local chunk_key = chunk.x .. ',' .. chunk.y

    -- prefilter the resources
    local filteredResources = {}
    for key, resource in pairs(resources) do
        if Resources.types[resource.name] ~= nil then
            table.insert(filteredResources, resource)
        end
    end

    for key, resource in pairs(filteredResources) do
        local pos = {
            x = math.floor(resource.position.x),
            y = math.floor(resource.position.y),
        }

        if not types[resource.name] then
            types[resource.name] = {
                id = 0,
                type = resource.name,
                name = Util.Naming.getRandomName(pos),
                surface = surface.index,
                chunks = {},
                initial_amount = 0,
                since = game.tick,
                index = 0,
                area = { top = pos.y, bottom = pos.y, left = pos.x, right = pos.x },
                tracking = settings.global['dqol-resource-monitor-site-track-new'].value,
            }

            types[resource.name].chunks[chunk_key] = {
                x = chunk.x,
                y = chunk.y,
                tiles = 0,
                amount = 0,
                updated = game.tick,
                borders = {
                    top = 0,
                    bottom = 0,
                    left = 0,
                    right = 0,
                },
            }
        end

        local site = types[resource.name]
        local chunk = site.chunks[chunk_key]

        -- update chunk
        chunk.amount = chunk.amount + resource.amount
        chunk.tiles = chunk.tiles + 1

        -- update site
        site.initial_amount = site.initial_amount + (resource.initial_amount or resource.amount)
        Sites.site.updateCalculated(site)

        -- check for borders
        local modX = pos.x % 32
        local modY = pos.y % 32

        if modX == 0 then
            chunk.borders.left = bit32.bor(chunk.borders.left, bit32.lshift(1, modY))
        elseif modX == 31 then
            chunk.borders.right = bit32.bor(chunk.borders.right, bit32.lshift(1, modY))
        end

        if modY == 0 then
            chunk.borders.top = bit32.bor(chunk.borders.top, bit32.lshift(1, modX))
        elseif modY == 31 then
            chunk.borders.bottom = bit32.bor(chunk.borders.bottom, bit32.lshift(1, modX))
        end

        -- expand area
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

    for _, site in pairs(types) do
        update_site_area_center(site.area)
        Sites.storage.insert(site)
    end
end

---@param surface uint
function Sites.deleteSurface(surface)
    local types = Sites.storage.getSurfaceSubList(surface)

    for _, sites in pairs(types) do
        for __, site in pairs(sites) do
            Sites.storage.remove(site)
        end
    end
end

---@param surface uint
---@param chunk {x: integer, y: integer}
function Sites.deleteChunk(surface, chunk)
    local chunk_key = chunk.x .. ',' .. chunk.y

    local types = Sites.storage.getSurfaceSubList(surface)
    for _, sites in pairs(types) do
        for __, site in pairs(sites) do
            -- now check if this site has this chunk
            if site.chunks[chunk_key] ~= nil then
                Sites.site.updateCalculated(site, site.calculated.amount - site.chunks[chunk_key].amount)
                site.chunks[chunk_key] = nil

                -- remove the site if it is effectively deleted now
                if table_size(site.chunks) == 0 then
                    Sites.storage.remove(site)
                end
            end
        end
    end
end

function Sites.resetGlobal()
    storage.sites = {
        surfaces = {},
        ids = {},
        updater = {
            queue = {},
            pointer = 1,
        },
    }
end

---@param site Site
---@param amount integer?
function Sites.site.updateCalculated(site, amount)
    if amount == nil then
        -- calculate it from all the chunks
        amount = 0
        for _, chunk in pairs(site.chunks) do amount = amount + chunk.amount end
    end

    local lastAmount = 0
    local lastAmountTick = 0
    local rate = 0
    local estimatedDepletion = nil
    if site.calculated and site.calculated.last_amount_tick then
        if site.calculated.last_amount_tick < game.tick - settings.global['dqol-resource-monitor-site-estimation-threshold'].value then
            -- calculate rate of depletion per second 
            local perTick = (site.calculated.last_amount - amount) / (game.tick - site.calculated.last_amount_tick)
            rate = math.ceil(perTick * 60)
            lastAmount = amount
            lastAmountTick = game.tick
            -- make sure there is no division by zero
            if perTick ~= 0 then
                estimatedDepletion = math.floor(amount / perTick)
            else
                -- make sure empty sites are depleting now
                if amount ~= 0 then
                    estimatedDepletion = nil
                else
                    estimatedDepletion = 0
                end
            end
        else
            rate = site.calculated.rate
            lastAmount = site.calculated.last_amount
            lastAmountTick = site.calculated.last_amount_tick
            estimatedDepletion = site.calculated.estimated_depletion
        end
    end

    site.calculated = {
        updated_at = game.tick,
        amount = amount,
        rate = rate,
        percent = amount / site.initial_amount,
        estimated_depletion = estimatedDepletion,
        last_amount = lastAmount,
        last_amount_tick = lastAmountTick,
    }

    -- cap percent
    if site.calculated.percent > 1 then site.calculated.percent = 1 end
end

---@param site Site
function Sites.site.updateMapTag(site)
    if settings.global['dqol-resource-monitor-site-map-markers'].value == true then
        local text = site.name .. ' ' .. Util.Integer.toExponentString(site.calculated.amount)
        if site.map_tag == nil or site.map_tag.valid ~= true then
            site.map_tag = game.forces[Scanner.DEFAULT_FORCE].add_chart_tag(site.surface, {
                position = site.area,
                text = text,
                icon = Resources.getSignalId(site.type),
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

---@param site Site
---@return integer
function Sites.site.getTiles(site)
    local tiles = 0
    for _, chunk in pairs(site.chunks) do
        tiles = chunk.tiles + tiles
    end
    return tiles
end

---@param site Site
---@return integer
function Sites.site.getUpdated(site)
    local min = nil
    for _, chunk in pairs(site.chunks) do
        if min == nil or chunk.updated < min then min = chunk.updated end
    end
    return min or game.tick
end

---Add a new site to the cache
---@param site Site
function Sites.storage.insert(site)
    if not storage.sites.surfaces[site.surface] then storage.sites.surfaces[site.surface] = {} end
    if not storage.sites.surfaces[site.surface][site.type] then storage.sites.surfaces[site.surface][site.type] = {} end

    local chunks = {}
    local looseMerge = Resources.types[site.type].loose_merge or false
    if not looseMerge then
        chunks = get_outer_chunks(site)
    else
        for key, _ in pairs(site.chunks) do table.insert(chunks, key) end
    end

    -- now check if this borders any other sites
    local matches = {}
    for _, chunkKey in pairs(chunks) do
        local chunk = site.chunks[chunkKey]
        -- calculate the relevant neighbors first
        local neighborKeys = get_neighboring_chunk_keys(chunk, looseMerge)

        for neighborKey, d in pairs(neighborKeys) do
            local direction = d.direction
            local otherDirection = d.opposite
            local diagonal = d.diagonal
            for siteKey, otherSite in pairs(storage.sites.surfaces[site.surface][site.type]) do
                local otherChunk = otherSite.chunks[neighborKey]
                if otherChunk ~= nil then
                    if looseMerge then
                        matches[otherSite.id] = otherSite
                        break
                    end

                    -- now check if they actually match up
                    if diagonal == nil then
                        if bit32.band(chunk.borders[direction], otherChunk.borders[otherDirection]) > 0 then
                            matches[otherSite.id] = otherSite
                            break
                        end
                    elseif diagonal == 'left' then
                        if bit32.band(otherChunk.borders[otherDirection], 2147483648) then
                            matches[otherSite.id] = otherSite
                            break
                        end
                    else -- diagonal == right
                        if bit32.band(otherChunk.borders[otherDirection], 1) then
                            matches[otherSite.id] = otherSite
                            break
                        end
                    end
                end
            end
        end
    end

    -- check for the matches array
    if table_size(matches) > 0 then
        for _, otherSite in pairs(matches) do
            -- merge into here
            otherSite = merge_sites(otherSite, site)

            -- update map tag
            Sites.site.updateMapTag(otherSite)

            if _DEBUG then
                game.print('Merge into site #' .. otherSite.id .. ' ' .. otherSite.name)
            end

            if site.id > 0 then
                -- the old site existed before
                -- now that they are merged the old one can be removed
                Sites.storage.remove(site)

                if _DEBUG then
                    game.print('Removed #' .. site.id .. ' after merge')
                end
            end

            -- swap site for next match
            site = otherSite
        end
    else
        -- we did find any matches, so we simply add it now
        local index = #storage.sites.surfaces[site.surface][site.type] + 1
        site.index = index
        storage.sites.surfaces[site.surface][site.type][index] = site
    
        -- add to ids
        local nextId = #(storage.sites.ids) + 1
        site.id = nextId
        storage.sites.ids[nextId] = site

        -- update map tag
        Sites.site.updateMapTag(site)
    
        if _DEBUG then
            game.print('Added new site #' .. site.id .. ' ' .. site.name)
        end
    end
end

---@return table<integer, table<string, Site[]?>>
function Sites.storage.getSurfaceList()
    return storage.sites.surfaces
end

---@return table<string, Site[]?>
function Sites.storage.getSurfaceSubList(index)
    return storage.sites.surfaces[index] or {}
end

---Get site from cache using ID
---@param id integer
---@return Site?
function Sites.storage.getById(id)
    return storage.sites.ids[id] or nil;
end

---Get site from cache, just by ID
---@return table<integer, Site>
function Sites.storage.getIdList()
    return storage.sites.ids
end

---@param site Site
function Sites.storage.remove(site)
    if site.map_tag ~= nil then site.map_tag.destroy() end
    storage.sites.ids[site.id] = nil
    storage.sites.surfaces[site.surface][site.type][site.index] = nil
end

function Sites.storage.clean()
    if storage.sites == nil then return end

    -- remove sites that make no sense
    ---@type GlobalSites
    local data = storage.sites
    for _, surface in pairs(data.surfaces) do
        for type, sites in pairs(surface) do
            if Resources.types[type] == nil then
                -- this resource does not exist, now remove
                for _, site in pairs(sites) do
                    game.print('Removing invalid site (' .. type .. '): ' .. site.name)
                    Sites.storage.remove(site)
                end
            end
        end
    end
end

---@param siteId integer
---@param chunkKey SiteChunkKey
function Sites.updater.updateSiteChunk(siteId, chunkKey)
    local site = Sites.storage.getById(siteId)
    if site == nil then return nil end
    local chunk = site.chunks[chunkKey]
    if chunk == nil then return nil end

    local surface = game.surfaces[site.surface]
        local x = chunk.x * 32
        local y = chunk.y * 32
        local area = { left_top = { x = x, y = y }, right_bottom = { x = x + 32, y = y + 32 } }
        local resources = surface.find_entities_filtered {
            area = area,
            name = site.type,
        }

    local sum = 0
        for __, resource in pairs(resources) do
        sum = sum + resource.amount
        end
    -- incrementally update site amount
    Sites.site.updateCalculated(site, site.calculated.amount - (chunk.amount - sum))

    -- remove if empty
    if #resources == 0 then
        site.chunks[chunkKey] = nil
        return nil
    end

    chunk.amount = sum
    chunk.tiles = #resources
    chunk.updated = game.tick
end

---@param site Site
function Sites.updater.updateSite(site)
    for chunkKey, chunk in pairs(site.chunks) do
        Sites.updater.updateSiteChunk(site.id, chunkKey)
    end

    Sites.site.updateMapTag(site)
end

function Sites.updater.onIncremental()
    -- local profiler = game.create_profiler(false)
    local set = storage.sites.updater.queue[storage.sites.updater.pointer]
    if set == nil then
        if #(storage.sites.updater.queue) > 0 then
            Sites.updater.finishQueue()
            -- profiler.stop()
            -- game.print(profiler)
            -- game.print('Finish queue')
        else
            -- we need to generate a new queue now
            Sites.updater.createQueue()
            -- profiler.stop()
            -- game.print(profiler)
            -- game.print('Created queue')
        end
        return
    end

    for _, tuple in pairs(set) do
        Sites.updater.updateSiteChunk(tuple[1], tuple[2])
    end

    storage.sites.updater.pointer = storage.sites.updater.pointer + 1

    -- profiler.stop()
    -- game.print(profiler)
    -- game.print('Update ' .. global.sites.updater.pointer .. ' of ' .. #(global.sites.updater.queue) .. ' (' .. #set .. ' chunks)')
end

function Sites.updater.onAll()
    -- local profiler = game.create_profiler(false)
    for siteId, site in pairs(Sites.storage.getIdList()) do
        if site.tracking then
            Sites.updater.updateSite(site)
        end
    end
    -- profiler.stop()
    -- game.print(profiler)
end

function Sites.updater.createQueue()
    local queue = {{}}
    local currentSet = 1
    local setSize = settings.global['dqol-resource-monitor-site-chunks-per-update'].value
    for siteId, site in pairs(Sites.storage.getIdList()) do
        if site.tracking and Resources.types[site.type].tracking_ignore == false then
            for chunkId, chunk in pairs(site.chunks) do
                if #(queue[currentSet]) >= setSize then
                    -- start a new set
                    currentSet = currentSet + 1
                    queue[currentSet] = {}
                end
                -- insert into the current set
                table.insert(queue[currentSet], { siteId, chunkId })
            end
        end
    end
    storage.sites.updater = {
        queue = queue,
        pointer = 1,
    }
end

function Sites.updater.finishQueue()
    -- go through all the sites and update their tags
    local sites = {}
    for _, set in pairs(storage.sites.updater.queue) do
        for __, tuple in pairs(set) do
            local siteId = tuple[1]
            local site = Sites.storage.getById(siteId)
            if sites[siteId] ~= true then
                sites[siteId] = true
                if site then
                    Sites.site.updateMapTag(site)
                end
            end
        end
    end

    -- update the surfaces now
    Surfaces.updateAll();

    storage.sites.updater.queue = {}
end

function Sites.boot()
    local func = Sites.updater.onIncremental
    if settings.global['dqol-resource-monitor-site-chunks-per-update'].value == 0 then
        func = Sites.updater.onAll
    end
    script.on_nth_tick(settings.global['dqol-resource-monitor-site-ticks-between-updates'].value, func)
end

function Sites.onInitMod()
    Sites.resetGlobal()
end
