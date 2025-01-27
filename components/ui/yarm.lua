UiYARM = {}

Ui.Menu.tabs.yarm = {}

---@param tab LuaGuiElement
function Ui.Menu.tabs.yarm.create(tab)
    tab.add {
        type = 'label',
        caption = { 'dqol-resource-monitor.ui-menu-yarm-import-tooltip' },
        style = 'info_label',
    }
    tab.add {
        type = 'button',
        caption = { 'dqol-resource-monitor.ui-menu-yarm-import' },
        tooltip = { 'dqol-resource-monitor.ui-menu-yarm-import-tooltip' },
        tags = {
            _callback = 'yarm_import',
        },
    }
end

---@param tab LuaGuiElement
function Ui.Menu.tabs.yarm.fill(tab)
end

---@param pos MapPosition
---@return ChunkPosition
local function position_to_chunk(pos)
    return { x = math.floor(pos.x / 32), y = math.floor(pos.y / 32) }
end

function Ui.callbacks.yarm_import(event)
    local player = game.players[event.player_index]

    local remote = remote.call('YARM', 'get_global_data')
    local yarm_sites = ((remote['force_data'] or {})[player.force.name] or {})['ore_sites'] or {}
    local entities = (remote['ore_tracker'] or {})['entities'] or {}

    player.print({ 'dqol-resource-monitor.ui-print-yarm-import', #yarm_sites })

    if #entities == 0 or yarm_sites == 0 then
        return
    end

    -- first delete all sites
    for _, surface in pairs(Surfaces.storage.all()) do
        Ui.Surface.onReset(surface, player)
    end


    -- loop all the sites
    local success = {}
    for _, yarm_site in pairs(yarm_sites) do
        local name = yarm_site.name_tag or ''
        if name == '' then name = yarm_site.index .. '' end

        -- get all the entities related to this site
        -- and sort them into chunks
        local chunks = {} ---@type table<string, ChunkPosition>
        for index, __ in pairs(yarm_site.tracker_indices) do
            local entity = entities[index]

            if entity and entity.valid and entity.entity then
                -- calculate chunk from position
                local chunk = position_to_chunk(entity.entity.position)
                chunks[chunk.x .. ',' .. chunk.y] = chunk
            end
        end

        -- skip if this is a summary site
        if yarm_site.is_summary then
            chunks = {}
        end
        
        local types_chunks = {}
        -- now process all chunks into sites
        for chunk_key, chunk in pairs(chunks) do
            local cache = {}
            Scanner.scan_chunk(yarm_site.surface, chunk, cache)
            
            for type, site in pairs(cache) do
                if types_chunks[type] == nil then
                    types_chunks[type] = {}
                end

                table.insert(types_chunks[type], site)
            end
        end

        for type, site_partials in pairs(types_chunks) do
            -- merge the partial sites into one site per type
            local site = nil ---@type Site?
            for _, partial in pairs(site_partials) do
                if site == nil then
                    site = partial
                else
                    Sites.merge(site, partial)
                end
            end

            if site ~= nil then
                -- this is looking promising
                site.name = name
                site.since = yarm_site.added_at
                if site.calculated.amount < yarm_site.initial_amount then
                    site.initial_amount = yarm_site.initial_amount
                    Sites.site.updateCalculated(site)
                end
                site.tracking = true
                
                -- finally store this data
                Sites.storage.insert(site)
                
                if site.id > 0 then
                    player.print({ 'dqol-resource-monitor.ui-print-now-tracking', name })
                else
                    -- the site was merged somehow
                    player.print({ 'dqol-resource-monitor.ui-print-import-merged', name })
                end

                table.insert(success, yarm_site)
            end
        end
    end

    -- now re-scan the surfaces
    settings.global['dqol-resource-monitor-site-track-new-default'] = {value = false}
    for _, surface in pairs(Surfaces.storage.all()) do
        Ui.Surface.onScan(surface, player)
    end

    -- delete sites from YARM
    -- not possible through remote, we cannot write YARM data

    -- open sites tab
    Ui.Menu.switchToTab(player, 1)
    Ui.Menu.show(player)
end

return UiYARM
