-- local Chunk = require('__stdlib__/stdlib/area/chunk')
local Position = require('__stdlib__/stdlib/area/position')


Scanner = {
    DEFAULT_FORCE = 1,
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
        for type, sites in pairs(Sites.get_sites_from_cache(surface.index)) do
            for key, site in pairs(sites) do
                Sites.highlight_site(site)
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
    if _DEBUG then
        game.print('Scanning chunk [' .. chunk.x .. ', ' .. chunk.y .. ']')
    end

    local area = chunk_to_area(chunk)
    local resources = surface.find_entities_filtered {
        area = area,
        type = 'resource',
    }

    if #resources == 0 then
        return false
    end

    local sites = Sites.create_from_chunk_resources(resources, surface, chunk)
    Sites.add_sites_to_cache(sites)

    return true
end

function on_chunk_charted(event)
    if event.force.index == Scanner.DEFAULT_FORCE then
        Scanner.scan_chunk(game.surfaces[event.surface_index], event.position)
    end
end

function Scanner.boot()
    if settings.global['dqol-resource-monitor-site-auto-scan'].value then
        script.on_event(defines.events.on_chunk_charted, on_chunk_charted)
        -- todo: on chunk deleted?
    end
end
