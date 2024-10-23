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
---@param chunk ChunkPositionAndArea
function Scanner.scan_chunk(surface, chunk)
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

    Sites.createFromChunkResources(resources, surface, chunk)

    return true
end

---@alias ScannerCache {chunks: table<integer, table<string, boolean>>}
---chunks: first index is the surface index, inner index is position_to_key of that chunk


---@return ScannerCache
function Scanner.cache.get()
    if global.scanner == nil then Scanner.cache.reset() end
    return global.scanner
end

function Scanner.cache.reset()
    global.scanner = {
        chunks = {}
    }
end

---@param surfaceId integer
function Scanner.cache.resetSurface(surfaceId)
    if global.scanner == nil then
        Scanner.cache.reset()
    else
        global.scanner.chunks[surfaceId] = {}
    end
end

---@param surfaceId integer
---@param chunk ChunkPositionAndArea
---@return boolean
function Scanner.cache.getChunk(surfaceId, chunk)
    local cache = Scanner.cache.get()
    if cache.chunks[surfaceId] == nil then cache.chunks[surfaceId] = {} end
    local key = chunk.x .. ',' .. chunk.y
    if cache.chunks[surfaceId][key] == nil then cache.chunks[surfaceId][key] = false end
    return cache.chunks[surfaceId][key]
end

---@param surfaceId integer
---@param chunk ChunkPositionAndArea
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

function Scanner.boot()
    if settings.global['dqol-resource-monitor-site-auto-scan'].value then
        script.on_event(defines.events.on_chunk_charted, on_chunk_charted)
    end

    script.on_event(defines.events.on_chunk_deleted, on_chunk_deleted)
    script.on_event(defines.events.on_surface_deleted, on_surface_deleted)
    script.on_event(defines.events.on_surface_created, on_surface_created)
end

function Scanner.onInitMod()
    Scanner.cache.reset()
end
