-- local Chunk = require('__stdlib__/stdlib/area/chunk')
local Position = require('__stdlib__/stdlib/area/position')


scanner = {}

function scanner.scan_all()
    for index, surface in pairs(game.surfaces) do
        scanner.scan_surface(surface)
    end
end

---@param surface LuaSurface
function scanner.scan_surface(surface)
    Sites.reset_cache() -- TODO remove ?!

    local force = game.player.force

    for chunk in surface.get_chunks() do
        if force.is_chunk_charted(surface, chunk) then
            local scanned = scanner.scan_chunk(surface, chunk)
            -- if scanned then return nil end
        end
    end

    for type, sites in pairs(Sites.get_sites_from_cache(surface.index)) do
        for key, site in pairs(sites) do
            game.print(site.name .. ' ' .. site.type ..
                ' at ' .. Position.to_key(site.positions[1]) .. ' ' .. site.amount .. '(' .. site.initial_amount .. ')')
        end
    end

    -- highlight the sites if debug is on
    if _DEBUG or false then
        for type, sites in pairs(Sites.get_sites_from_cache(surface.index)) do
            for key, site in pairs(sites) do
                game.print(site.name .. ' ' .. site.type ..
                    ' at ' ..
                    Position.to_key(site.positions[1]) .. ' ' .. site.amount .. '(' .. site.initial_amount .. ')')
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
function scanner.scan_chunk(surface, chunk)
    -- game.print('Scanning chunk [' .. chunk.x .. ', ' .. chunk.y .. ']')

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
