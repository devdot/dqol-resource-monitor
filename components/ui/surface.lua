local UiSurface = {}

---@param surface Surface
---@param window LuaGuiElement
function UiSurface.show(surface, window)
    Ui.Window.clearInner(window)
    local inner = window.inner

    -- gather data
    local chunks = Scanner.cache.get().chunks[surface.id] or {}
    local sitesByType = Sites.storage.getSurfaceSubList(surface.id)

    -- some info
    local info = inner.add { type = 'table', column_count = 2 }
    if script.active_mods['space-exploration'] then
        info.add { type = 'label', caption =  {'dqol-resource-monitor.ui-colon', { 'dqol-resource-monitor.ui-surface-zonetype' } } }
        local icon = remote.call("space-exploration", "get_zone_icon", {zone_index = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface.id}).index})
        info.add { type = 'label', caption = '[img=' .. icon .. ']' }
    end
    info.add { type = 'label', caption =  {'dqol-resource-monitor.ui-colon', { 'dqol-resource-monitor.ui-surface-id' } } }
    info.add { type = 'label', caption = '#' .. surface.id }
    info.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', { 'dqol-resource-monitor.ui-surface-chunks' } } }
    info.add { type = 'label', caption = table_size(chunks) }
    

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    -- resources
    -- build data
    local resources = {}
    local maxResourceValue = 0
    for resource, sites in pairs(sitesByType) do
        local skip = false
        if string.sub(resource, 1, 7) == 'se-core' then
            skip = true
        end

        if skip == false then
            local sum = 0
            local sum_tracking = 0
            local sites_tracking = 0
            for __, site in pairs(sites or {}) do
                sum = sum + site.amount
                if site.tracking == true then
                    sum_tracking = sum_tracking + site.amount
                    sites_tracking = sites_tracking + 1
                end
            end

            if sum > maxResourceValue then maxResourceValue = sum end

            local data = {
                type = Resources.types[resource],
                sites = table_size(sites),
                sites_tracking = sites_tracking,
                sum = sum,
                sum_display = Util.Integer.toExponentString(sum),
                sum_tracking = sum_tracking,
                sum_tracking_display = Util.Integer.toExponentString(sum_tracking),
            }
            table.insert(resources, data)
        end
    end
    if maxResourceValue == 0 then maxResourceValue = 1 end

    -- sort data
    
    local function compare_resources(a, b)
        return a.sum > b.sum
    end
    table.sort(resources, compare_resources)

    -- display data
    local resource_flow = inner.add { type = 'flow', direction = 'vertical' }
    for _, data in pairs(resources) do
        local flow = resource_flow.add { type = 'flow', direction = 'horizontal' }
        flow.add { type = 'sprite', sprite = data.type.type .. '/' .. data.type.name }
        local subflow = flow.add { type = 'flow', direction = 'vertical' }
        local bar = subflow.add {
            type = 'progressbar',
            value = data.sum / maxResourceValue,
            caption = data.sum_display .. ' (' .. data.sites .. ')',
            style = 'dqol_resource_monitor_resource_bar',
            tooltip = { 'dqol-resource-monitor.ui-surface-resource-sum-total', data.sum_display, data.sites },
        }
        bar.style.color = data.type.color
        bar.style.bar_width = 14
        bar.style.bottom_margin = -4
        local bar = subflow.add {
            type = 'progressbar',
            value = data.sum_tracking / maxResourceValue,
            caption = data.sum_tracking_display .. ' (' .. data.sites_tracking .. ')',
            style = 'dqol_resource_monitor_resource_bar',
            tooltip = { 'dqol-resource-monitor.ui-surface-resource-sum-tracking', data.sum_tracking_display, data.sites_tracking },
        }
        bar.style.color = data.type.color
        bar.style.bar_width = 14
    end

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    -- buttons at the bottom
    local buttons = inner.add { type = 'table', style = 'compact_slot_table', column_count = 7 }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-scan-tooltip' },
        sprite = 'utility/reset',
        tags = {
            _module = 'surface',
            _action = 'scan',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-auto-track-tooltip' },
        sprite = 'item/electric-mining-drill',
        tags = {
            _module = 'surface',
            _action = 'auto_track',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-track-all-tooltip' },
        sprite = 'utility/check_mark',
        tags = {
            _module = 'surface',
            _action = 'track_all',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-untrack-all-tooltip' },
        sprite = 'utility/close_black',
        tags = {
            _module = 'surface',
            _action = 'untrack_all',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-add-map-tags' },
        sprite = 'utility/custom_tag_in_map_view',
        tags = {
            _module = 'surface',
            _action = 'add_map_tags',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-surface-remove-map-tags' },
        sprite = 'utility/custom_tag_in_map_view', -- todo: find better icon
        tags = {
            _module = 'surface',
            _action = 'remove_map_tags',
            surface_id = surface.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = {'dqol-resource-monitor.ui-surface-reset-tooltip'},
        sprite = 'utility/trash',
        tags = {
            _module = 'surface',
            _action = 'reset',
            surface_id = surface.id,
        },
    }
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onScan(surface, player)
    Scanner.scan_surface(game.surfaces[surface.id])
    Ui.Menu.onSurfaceShow(surface, player)
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onAutoTrack(surface, player)
    local types = Sites.storage.getSurfaceSubList(surface.id)
    local luaSurface = game.surfaces[surface.id]
    local found = false
    for type, inner in pairs(types or {}) do
        local skipType = string.sub(type, 1, 7) == 'se-core'
        for __, site in pairs((skipType == false and inner) or {}) do
            if site.tracking == false then
                local miners = luaSurface.count_entities_filtered {
                    area = { left_top = { x = site.area.left, y = site.area.top }, right_bottom = { x = site.area.right, y = site.area.bottom } },
                    type = 'mining-drill',
                }

                if miners > 0 then
                    site.tracking = true
                    found = true
                end
                player.print('Now tracking ' .. site.name)
            end
        end
    end
    if found == false then player.print('Could not find any untracked sites with miners') end
    Ui.Menu.onSurfaceShow(surface, player)
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onReset(surface, player)
    Scanner.cache.resetSurface(surface.id)
    local sites = Sites.storage.getSurfaceSubList(surface.id)
    for _, inner in pairs(sites) do
        for __, site in pairs(inner) do
            Sites.storage.remove(site)
        end
    end
    Surfaces.surface.delete(surface.id)
    Surfaces.generateFromGame(game.surfaces[surface.id]) -- the surface was not really deleted, so we need to recreate it
    Ui.Menu.onSurfaceShow(surface, player)
end

local function surface_tracking_helper(surfaceId, tracking)
    for _, sites in pairs(Sites.storage.getSurfaceSubList(surfaceId)) do
        for __, site in pairs(sites) do
            site.tracking = tracking
        end
    end
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onTrackAll(surface, player)
    surface_tracking_helper(surface.id, true)
    Ui.Menu.onSurfaceShow(surface, player)
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onUntrackAll(surface, player)
    surface_tracking_helper(surface.id, false)
    Ui.Menu.onSurfaceShow(surface, player)
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onAddMapTags(surface, player)
    for _, inner in pairs(Sites.storage.getSurfaceSubList(surface.id)) do
        for __, site in pairs(inner) do
            Sites.site.updateMapTag(site)
        end
    end
    Ui.Menu.onSurfaceShow(surface, player)
end

---@param surface Surface
---@param player LuaPlayer
function UiSurface.onRemoveMapTags(surface, player)
    for _, inner in pairs(Sites.storage.getSurfaceSubList(surface.id)) do
        for __, site in pairs(inner) do
            if site.tracking == false and site.map_tag and site.map_tag.valid then
                site.map_tag.destroy()
                site.map_tag = nil
            end
        end
    end
    Ui.Menu.onSurfaceShow(surface, player)
end

return UiSurface
