local UiSite = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-site',
}

---@param site Site
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiSite.show(site, player, window)
    -- create a new window if needed
    if window == nil then
        window = Ui.Window.create(player, 'site' .. site.id, site.name)
    else
        Ui.Window.refreshTitle(window, site.name)
        Ui.Window.clearInner(window)
    end

    local inner = window.inner

    local table = inner.add { type = 'table', column_count = 2 }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', 'ID'} }
    table.add { type = 'label', caption = '#' .. site.id }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-surface'}} }
    table.add { type = 'label', caption = game.surfaces[site.surface].name .. ' [' .. site.surface .. ']' }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-tiles'}} }
    table.add { type = 'label', caption = #site.positions }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-amount'}} }
    table.add { type = 'label', caption = Util.Integer.toExponentString(site.amount) }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-initial-amount'}} }
    table.add { type = 'label', caption = Util.Integer.toExponentString(site.initial_amount) }
    table.add { type = 'label', caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-created'}} }
    table.add { type = 'label', caption = Util.Integer.toTimeString(site.since) .. ' (' .. Util.Integer.toTimeString(game.tick - site.since) ..' ago)' }

    inner.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    
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
        tooltip = { 'dqol-resource-monitor.ui-site-highlight-tooltip' },
        sprite = 'utility/show_tags_in_map_view',
        tags = {
            _module = 'site',
            _action = 'highlight',
            site_id = site.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
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
    Sites.highlight_site(site)
    player.zoom_to_world(site.area)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onUpdate(site, player, event)
    Sites.update_cached_site(site) -- todo: will this mess up multiplayer game sync?
    local window = Ui.Window.getWindowFromEvent(event) or Ui.Window.get(player, 'site' .. site.id)
    UiSite.show(site, player, window)
end

return UiSite
