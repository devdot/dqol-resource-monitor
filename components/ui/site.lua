local UiSite = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-site',
}

---@param site Site
---@return double
local function calculate_zoom(site)
    local width = site.area.right - site.area.left
    local height = site.area.top - site.area.bottom
    local extend = width
    if height > width then extend = height end

    local zoom = 10 / extend
    if zoom > 0.75 then zoom = 0.75 end
    if zoom < 0.125 then zoom = 0.125 end
    return zoom
end

---@param site Site
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiSite.show(site, player, window)
    local title = Resources.getIconString(site.type) .. ' ' .. site.name
    local product = Resources.getProduct(site.type)

    -- create a new window if needed
    if window == nil then
        window = Ui.Window.create(player, 'site' .. site.id, title)
    else
        Ui.Window.refreshTitle(window, title)
        Ui.Window.clearInner(window)
    end

    local inner = window.inner

    local subflow = inner.add { type = 'flow', direction = 'vertical' }
    local bar = subflow.add {
        type = 'progressbar',
        value = site.calculated.percent,
        caption = Util.Integer.toExponentString(site.calculated.amount),
        style = 'dqol_resource_monitor_resource_bar',
        tooltip = Util.Integer.toExponentString(site.calculated.amount, 2) .. ' / ' .. Util.Integer.toExponentString(site.initial_amount, 2),
    }
    bar.style.color = Resources.types[site.type].color
    bar.style.bar_width = 16
    bar.style.bottom_margin = -4

    local table = inner.add { type = 'table', column_count = 2 }
    local stats = {
        {'type', {(product and product.type .. '-name.' .. product.name) or ('entity-name.' .. site.type)}},
        {'amount', Util.Integer.toExponentString(site.calculated.amount, 2)},
        {'initial-amount', Util.Integer.toExponentString(site.initial_amount, 2)},
        {'percent', Util.Integer.toPercent(site.calculated.percent)},
        {'rate', Util.Integer.toExponentString(site.calculated.rate, 2) .. '/s'},
        {'estimated-depletion', Util.Integer.toTimeString(site.calculated.estimated_depletion, 'never')},
        {'id', '#' .. site.id},
        {'surface', game.surfaces[site.surface].name .. ' [' .. site.surface .. ']'},
        {'tiles', Sites.site.getTiles(site)},
        {'chunks', table_size(site.chunks)},
        {'created', Util.Integer.toTimeString(site.since) .. ' (' .. Util.Integer.toTimeString(game.tick - site.since) ..' ago)'},
        {'updated', Util.Integer.toTimeString(site.calculated.updated_at) .. ' (' .. Util.Integer.toTimeString(game.tick - site.calculated.updated_at) ..' ago)'},
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

    local camera = inner.add {
        type = 'camera',
        position = { x = site.area.x, y = site.area.y },
        surface_index = site.surface,
        zoom = calculate_zoom(site),
        tags = {
            _module = 'site',
            _action = 'highlight',
            site_id = site.id,
        },
    }
    camera.style.size = 300

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    local buttons = inner.add { type = 'flow' }
    buttons.add {
        type = 'sprite-button',
        style = 'slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-highlight-tooltip' },
        sprite = 'utility/go_to_arrow',
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
    buttons.add {
        type = 'sprite-button',
        style = 'slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-delete-tooltip' },
        sprite = 'utility/trash',
        tags = {
            _module = 'site',
            _action = 'delete',
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
    if script.active_mods["space-exploration"] ~= nil then
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
        local entity = game.surfaces[site.surface].find_entities_filtered{
            area = {left_top = {x = site.area.x - 1, y = site.area.y - 1}, right_bottom = {x = site.area.x + 1, y = site.area.y + 1}},
            limit = 1,
        }[1] or game.surfaces[site.surface].find_entities_filtered {
            area = {left_top = {x = site.area.left, y = site.area.top}, right_bottom = {x = site.area.right, y = site.area.bottom}},
            limit = 1,
        }[1] or nil

        if entity then
            player.centered_on = entity
        else
            player.print('Could not find an entity to center on!')
        end
    end
end

---@param site Site
---@param player LuaPlayer
function UiSite.onUpdate(site, player, event)
    Sites.updater.updateSite(site)
    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    UiSite.show(site, player, window)
end

function UiSite.onDelete(site, player, event)
    if site ~= nil then
        Sites.storage.remove(site)
        
        -- close the site window (if it exists)
        Ui.Window.close(player, 'site' .. site.id)
    end

    -- refresh the menu if open
    if Ui.Menu.isOpen(player) then
        Ui.Menu.show(player)
    end
end

---@param site Site
---@param player LuaPlayer
function UiSite.onToggleTracking(site, player, event)
    site.tracking = event.element.state or false

    -- immediately update the site
    Sites.updater.updateSite(site)

    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    UiSite.show(site, player, window)
end

return UiSite
