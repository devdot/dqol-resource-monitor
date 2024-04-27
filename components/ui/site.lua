local UiSite = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-site',
}

---@param site Site
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiSite.show(site, player, window)
    local type = Resources.types[site.type]
    local title = '[' .. type.type .. '=' .. type.name .. '] ' .. site.name

    -- create a new window if needed
    if window == nil then
        window = Ui.Window.create(player, 'site' .. site.id, title)
    else
        Ui.Window.refreshTitle(window, title)
        Ui.Window.clearInner(window)
    end

    local inner = window.inner

    local table = inner.add { type = 'table', column_count = 2 }
    local updated = Sites.site.getUpdated(site)
    local stats = {
        {'type', {type.type .. '-name.' .. type.name}},
        {'amount', Util.Integer.toExponentString(site.amount)},
        {'initial-amount', Util.Integer.toExponentString(site.initial_amount)},
        {'id', '#' .. site.id},
        {'surface', game.surfaces[site.surface].name .. ' [' .. site.surface .. ']'},
        {'tiles', Sites.site.getTiles(site)},
        {'chunks', table_size(site.chunks)},
        {'created', Util.Integer.toTimeString(site.since) .. ' (' .. Util.Integer.toTimeString(game.tick - site.since) ..' ago)'},
        {'updated', Util.Integer.toTimeString(updated) .. ' (' .. Util.Integer.toTimeString(game.tick - updated) ..' ago)'},
    }
    for key, row in pairs(stats) do
        table.add {
            type = 'label',
            -- style = 'caption_label',
            caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-' .. row[1]}},
        }
        table.add { type = 'label', caption = row[2]}
    end
    
    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    
    inner.add {
        type = 'checkbox',
        state = site.tracking,
        caption = {'dqol-resource-monitor.ui-site-tracking-tooltip'},
        tags = {
            _only = defines.events.on_gui_checked_state_changed,
            _module = 'site',
            _action = 'toggle_tracking',
            site_id = site.id,
        },
    }

    
    local rename = inner.add { type = 'flow', name = 'rename' }
    rename.add {
        type = 'textfield',
        name = 'rename',
        text = site.name,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
        tags = {
            _only = defines.events.on_gui_confirmed,
            _module = 'site',
            _action = 'rename',
            site_id = site.id,
        },
    }
    rename.add {
        type = 'button',
        caption = { 'dqol-resource-monitor.ui-ok' },
        style = 'item_and_count_select_confirm',
        tags = {
            _module = 'site',
            _action = 'rename',
            site_id = site.id,
        },
    }

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    local camera = inner.add { type = 'camera', position = {x = site.area.x, y = site.area.y}, surface_index = site.surface, zoom = 0.5 }
    camera.style.size = 300

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    local buttons = inner.add { type = 'flow' }
    buttons.add {
        type = 'sprite-button',
        style = 'slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-highlight-tooltip' },
        sprite = 'utility/reference_point',
        tags = {
            _module = 'site',
            _action = 'highlight',
            site_id = site.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-update-tooltip' },
        sprite = 'utility/refresh',
        tags = {
            _module = 'site',
            _action = 'update',
            site_id = site.id,
        },
    }
end

---@param site Site
---@param player LuaPlayer
function UiSite.onShow(site, player, event)
    UiSite.show(site, player) -- todo: find out from the event if we should pass a window or not    
end

---@param site Site
---@param player LuaPlayer
function UiSite.onRename(site, player, event)
    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    local textfield = window['inner']['rename']['rename']

    site.name = textfield.text

    Ui.Site.show(site, player, window)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onHighlight(site, player)
    Sites.site.highlight(site)

    -- show in game world
    if game.active_mods["space-exploration"] ~= nil then
        local zone = remote.call("space-exploration", "get_zone_from_surface_index", { surface_index = site.surface})
        if not zone then
            -- zone is not available?!
            player.print('Cannot go to zone!')
            return
        end
        remote.call("space-exploration", "remote_view_start",
            {
                player = player,
                zone_name = zone.name,
                position = site.area,
                location_name = site.name,
                freeze_history = true
            })
    else
        player.zoom_to_world(site.area)
    end
end

---@param site Site
---@param player LuaPlayer
function UiSite.onUpdate(site, player, event)
    Sites.updater.updateSite(site)
    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    UiSite.show(site, player, window)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onToggleTracking(site, player, event)
    site.tracking = event.element.state or false
    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    UiSite.show(site, player, window)
end

return UiSite
