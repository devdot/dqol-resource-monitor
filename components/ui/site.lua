local UiSite = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-site',
}

---@param site Site
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiSite.show(site, player, window)
    -- create a new window if needed
    if window == nil then
        window = Ui.Window.create(player, site.name)
    end

    local table = window.add { type = 'table', column_count = 2 }
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

    window.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    
    local rename = window.add { type = 'flow', name = 'rename' }
    rename.add {
        type = 'textfield',
        name = 'rename',
        text = site.name,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
    }
    rename.add { type = 'button', caption = {'dqol-resource-monitor.ui-ok'}, style = 'item_and_count_select_confirm', name =  UiSite.ROOT_FRAME .. '-rename-' .. site.id}

    window.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    local camera = window.add { type = 'camera', position = {x = site.area.x, y = site.area.y}, surface_index = site.surface, zoom = 0.5 }
    camera.style.size = 300

    window.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }

    local buttons = window.add { type = 'flow' }
    buttons.add { type = 'sprite-button', tooltip = {'dqol-resource-monitor.ui-site-highlight-tooltip'}, sprite = 'utility/show_tags_in_map_view', name = UiSite.ROOT_FRAME .. '-highlight-' .. site.id }
    buttons.add { type = 'sprite-button', tooltip = {'dqol-resource-monitor.ui-site-update-tooltip'}, sprite = 'utility/refresh', name = UiSite.ROOT_FRAME .. '-update-' .. site.id }
end

---@param site Site
---@param player LuaPlayer
function UiSite.onShow(site, player, event)
    UiSite.show(site, player) -- todo: find out from the event if we should pass a window or not    
end

---@param site Site
---@param player LuaPlayer
function UiSite.onRename(site, player)
    local textfield = Ui.Window.get(player)['rename']['rename']

    site.name = textfield.text

    Ui.Site.show(site, player) -- todo: update title on current window instead of re-creation
end

---@param site Site
---@param player LuaPlayer
function UiSite.onHighlight(site, player)
    Sites.highlight_site(site)
    player.zoom_to_world(site.area)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onUpdate(site, player)
    Sites.update_cached_site(site) -- todo: will this mess up multiplayer game sync?
    UiSite.show(site, player) -- todo: maybe pass the window if it exists?
end

return UiSite
