Scanner = {
    DEFAULT_FORCE = 1,
    cache = {},
}

---@return LuaForce
local function get_default_force()
    return game.forces[Scanner.DEFAULT_FORCE]    
end

function Scanner.scan_all()
    for index, surface in pairs(game.surfaces) do
        Scanner.scan_surface(surface)
    end
end

---@param surface LuaSurface
function Scanner.scan_surface(surface)
    local force = get_default_force()

    for chunk in surface.get_chunks() do
        if force.is_chunk_charted(surface, chunk) then
            Scanner.scan_chunk(surface, chunk)
        end
    end

    -- highlight the sites if debug is on
    if _DEBUG or false then
        for type, sites in pairs(Sites.storage.getSurfaceSubList(surface.index)) do
            for key, site in pairs(sites) do
                Sites.site.highlight(site)
            end
        end
    end
end

---@param chunk ChunkPositionAndArea
local function chunk_to_area(chunk)
    local x = chunk.x * 32
    local y = chunk.y * 32
    return {
        left_top = { x = x, y = y },
        right_bottom = { x = x + 32, y = y + 32 },
    }
end

---@param surface LuaSurface
---@param chunk ChunkPosition
---@param site_list table<string, Site>|nil
function Scanner.scan_chunk(surface, chunk, site_list)
    if Scanner.cache.getChunk(surface.index, chunk) then
        return false
    end

    if _DEBUG then
        log('Scanning chunk [' .. chunk.x .. ', ' .. chunk.y .. ']')
    end

    local area = chunk_to_area(chunk)
    local resources = surface.find_entities_filtered {
        area = area,
        type = 'resource',
    }

    Scanner.cache.setChunk(surface.index, chunk, true)

    if #resources == 0 then
        return false
    end

    Sites.createFromChunkResources(resources, surface, chunk, site_list)

    return true
end

---@param surface LuaSurface
---@param area {left_top: {x: float, y: float}, right_bottom: {x: float, y: float}}
---@param site_list table<string, Site>|nil
function Scanner.scan_area(surface, area, site_list)
    local resources = surface.find_entities_filtered {
        area = area,
        type = 'resource',
    }

    local chunk = {
        x = math.floor(area.left_top.x / 32),
        y = math.floor(area.left_top.y / 32),
    }

    Sites.createFromChunkResources(resources, surface, chunk, site_list)
end

---@alias ScannerCache {chunks: table<integer, table<string, boolean>>}
---chunks: first index is the surface index, inner index is position_to_key of that chunk


---@return ScannerCache
function Scanner.cache.get()
    if storage.scanner == nil then Scanner.cache.reset() end
    return storage.scanner
end

function Scanner.cache.reset()
    storage.scanner = {
        chunks = {}
    }
end

---@param surfaceId integer
function Scanner.cache.resetSurface(surfaceId)
    if storage.scanner == nil then
        Scanner.cache.reset()
    else
        storage.scanner.chunks[surfaceId] = {}
    end
end

---@param surfaceId integer
---@param chunk ChunkPosition
---@return boolean
function Scanner.cache.getChunk(surfaceId, chunk)
    local cache = Scanner.cache.get()
    if cache.chunks[surfaceId] == nil then cache.chunks[surfaceId] = {} end
    local key = chunk.x .. ',' .. chunk.y
    if cache.chunks[surfaceId][key] == nil then cache.chunks[surfaceId][key] = false end
    return cache.chunks[surfaceId][key]
end

---@param surfaceId integer
---@param chunk ChunkPosition
---@param bool boolean
function Scanner.cache.setChunk(surfaceId, chunk, bool)
    local cache = Scanner.cache.get()
    if cache.chunks[surfaceId] == nil then cache.chunks[surfaceId] = {} end
    local key = chunk.x .. ',' .. chunk.y
    cache.chunks[surfaceId][key] = bool
end

function on_chunk_charted(event)
    if event.force.index == Scanner.DEFAULT_FORCE then
        Scanner.scan_chunk(game.surfaces[event.surface_index], event.position)
    end
end

function on_chunk_deleted(event)
    for _, chunk in pairs(event.positions) do
        if _DEBUG then
            game.print('Deleting chunk [' .. chunk.x .. ', ' .. chunk.y .. ']')
        end

        Scanner.cache.setChunk(event.surface_index, chunk, false)
        Sites.deleteChunk(event.surface_index, chunk)
    end
end

function on_surface_deleted(event)
    if _DEBUG then
        game.print('Deleted surface #' .. event.surface_index)
    end

    Scanner.cache.resetSurface(event.surface_index)
    Sites.deleteSurface(event.surface_index)
    Surfaces.surface.delete(event.surface_index)
end

function on_surface_created(event)
    Surfaces.generateFromGame(game.surfaces[event.surface_index])
end

function on_built_entity(event)
    if event.entity.valid == nil then return end

    local profiler
    if _DEBUG then
        profiler = game.create_profiler()
    end

    -- using entity position might lead to miners not matching to the site when they are placed partially outside the site bounding box
    -- however, most people place some miner on the site so this is "good enough"
    local pos = event.entity.position
    local surface = event.entity.surface_index
    ---@type LuaPlayer?
    local player = (event.player_index and game.players[event.player_index]) or event.entity.last_user

    -- match this position with any site that could work
    local types = Sites.storage.getSurfaceList()[surface] or {}
    for _, sites in pairs(types) do
        for __, site in pairs(sites) do
            -- simply check if the position is within the area of this site
            local match = site.area.left <= pos.x and site.area.right >= pos.x and site.area.top <= pos.y and site.area.bottom >= pos.y
            if match then
                if site.tracking == false then
                    site.tracking = true
                    Sites.site.updateCalculated(site)

                    -- in strange circumstances, player can still be nil
                    local message = { 'dqol-resource-monitor.ui-print-now-tracking', Resources.getIconString(site.type) .. site.name }
                    if player then player.print(message) else game.print(message) end
                end

                -- don't look for this type anymore ... we assume there is at most one match per type
                break 
            end
        end
    end

    if _DEBUG then
        profiler.stop()
        game.print(profiler)
    end
end

local function py_bitumen_callback(_, meta, event)
    Scanner.py_update_bitumen_seep(meta.pos, meta.surface)
end

local function on_resource_depleted(event)
    -- this is only active with certain mods

    -- check for pyanodons bitumen seep
    ---@type LuaEntity
    local resource = event.entity
    if resource.name == 'bitumen-seep' and resource.valid then
        -- find the old site
        local site = nil
        local pos = resource.position
        for _, _site in pairs(Sites.storage.getSurfaceSubList(resource.surface.index)['bitumen-seep'] or {}) do
            -- we need some more margin to match the site with 0x0 dimension
            local match = (_site.area.left - 1) <= pos.x and (_site.area.right + 1) >= pos.x and
            (_site.area.top - 1) <= pos.y and (_site.area.bottom + 1) >= pos.y
            if match then
                site = _site
                break
            end
        end
        
        -- call for a re-scan of that chunk
        -- use the translation system as a callback for next tick
        -- todo: use a less hacky system for this
        Translation.request('bitumen' .. ((site and site.id) or '0'), py_bitumen_callback, {site_id = (site) and (site.id or nil), pos = pos, surface = resource.surface}) 

         -- remove the site now
        if site ~= nil then
            game.print('Removed site ' .. site.name) -- todo translation
            Sites.storage.remove(site)
        end
        return
    end
end

function Scanner.py_update_bitumen_seep(pos, surface)
    local sites = {}
    Scanner.scan_area(surface, {
        left_top = { x = pos.x - 0.5, y = pos.y - 0.5 },
        right_bottom = { x = pos.x + 0.5, y = pos.y + 0.5},
    }, sites)

    for _, site in pairs(sites) do
        site.tracking = true
        Sites.storage.insert(site)
        local message = { 'dqol-resource-monitor.ui-print-now-tracking', Resources.getIconString(site.type) .. site.name }
        game.print(message)
    end
end

function Scanner.boot()
    if settings.global['dqol-resource-monitor-site-auto-scan'].value then
        script.on_event(defines.events.on_chunk_charted, on_chunk_charted)
    end

    if settings.global['dqol-resource-monitor-site-track-miner-placed'].value then
        local filter = {{
            filter = 'type',
            type = 'mining-drill',
        }}
        script.on_event(defines.events.on_built_entity, on_built_entity, filter)
        script.on_event(defines.events.on_robot_built_entity, on_built_entity, filter)
    end

    script.on_event(defines.events.on_chunk_deleted, on_chunk_deleted)
    script.on_event(defines.events.on_surface_deleted, on_surface_deleted)
    script.on_event(defines.events.on_surface_created, on_surface_created)

    if script.active_mods['pypetroleumhandling'] then
        script.on_event(defines.events.on_resource_depleted, on_resource_depleted)
    end
end

function Scanner.onInitMod()
    Scanner.cache.reset()
end
