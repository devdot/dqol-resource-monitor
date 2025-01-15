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

---@param site_id integer
---@param outer LuaGuiElement
function UiSite.showInMenu(site_id, outer)
    local inner = outer.site
    inner.clear()
    outer.title.clear()
    outer.rename.clear()
    outer.details.clear()

    local site = Sites.storage.getById(site_id)
    if site == nil then
        return
    end

    local product = Resources.getProduct(site.type)
    local typeLocale = {(product and product.type .. '-name.' .. product.name) or ('entity-name.' .. site.type)}

    -- title
    outer.title.visible = true
    local renameOpenTags = {
        _module = 'site',
        _action = 'rename_open',
        site_id = site_id,
    }
    local icon = outer.title.add {
        type = 'sprite',
        name = 'icon',
        sprite = Resources.getSpriteString(site.type),
        tooltip = typeLocale,
    }
    icon.style.size = 24
    icon.style.stretch_image_to_widget_size = true
    icon.style.right_margin = 8
    local title = outer.title.add {
        type = 'label',
        name = 'title',
        style = 'heading_2_label',
        caption = site.name,
        tooltip = {'dqol-resource-monitor.ui-site-rename', site.name},
        tags = renameOpenTags,
    }
    title.style.horizontally_stretchable = true
    title.style.horizontally_squashable = true
    title.style.width = 356 -- 392 - 24 - 4 - 8
    
    -- rename field
    outer.rename.visible = false
    titleTextbox = outer.rename.add {
        name = 'textfield',
        type = 'textfield',
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
    titleTextbox.style.width = 360 -- 392 - 28 - 4
    titleTextbox.style.vertically_stretchable = true
    titleTextbox.style.height = 22
    outer.rename.add {
        name = 'confirm',
        type = 'button',
        caption = { 'dqol-resource-monitor.ui-ok' },
        style = 'item_and_count_select_confirm',
        tags = {
            _module = 'site',
            _action = 'rename',
            site_id = site.id,
        }
    }.style.height = 22

    -- fill bar
    local bar = inner.add {
        type = 'progressbar',
        value = site.calculated.percent,
        caption = Util.Integer.toExponentString(site.calculated.amount),
        style = 'dqol_resource_monitor_resource_bar',
        tooltip = {'dqol-resource-monitor.ui-site-remaining-bar', Util.Integer.toExponentString(site.calculated.amount, 2), Util.Integer.toExponentString(site.initial_amount, 2), typeLocale },
    }
    local barColor = Resources.types[site.type].color
    local barColorIsBright = (barColor.r + barColor.g + barColor.b) > 1
    bar.style.color = (barColorIsBright and barColor) or {barColor.r + 0.3, barColor.g + 0.3, barColor.b + 0.3}
    bar.style.bar_width = 16

    local buttons = inner.add { name = 'buttons', type = 'table', column_count = 6, style = 'compact_slot_table' }
    buttons.add {
        type = 'sprite-button',
        style = 'slot_sized_button_blue',
        tooltip = { 'dqol-resource-monitor.ui-site-tracking-tooltip' },
        sprite = 'dqol-resource-monitor-site-track',
        toggled = site.tracking,
        tags = {
            _module = 'site',
            _action = 'toggle_tracking',
            site_id = site.id,
        },
    }.style.size = 36
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-highlight-tooltip' },
        sprite = 'utility/center', -- maybe utility/map ?
        tags = {
            _module = 'site',
            _action = 'highlight',
            site_id = site.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = {'dqol-resource-monitor.ui-site-rename', site.name},
        sprite = 'utility/rename_icon',
        tags = renameOpenTags,
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
        tooltip = {'dqol-resource-monitor.ui-site-merge-tooltip', site.name},
        sprite = 'dqol-resource-monitor-site-merge',
        tags = {
            _module = 'site',
            _action = 'merge_open',
            site_id = site.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        style = 'compact_slot_sized_button',
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
        name = 'delete_open',
        style = 'compact_slot_sized_button',
        tooltip = { 'dqol-resource-monitor.ui-site-delete-tooltip' },
        sprite = 'utility/trash',
        tags = {
            _module = 'site',
            _action = 'delete_open',
            site_id = site.id,
        },
    }
    buttons.add {
        type = 'sprite-button',
        name = 'delete_confirm',
        visible = false,
        style = 'slot_sized_button_red',
        tooltip = { 'dqol-resource-monitor.ui-site-delete-tooltip' },
        sprite = 'utility/check_mark',
        tags = {
            _module = 'site',
            _action = 'delete',
            site_id = site.id,
        },
    }.style.size = 36

    local mergeGroup = inner.add { name = 'merge', type = 'flow', direction = 'horizontal', visible = false }
    mergeGroup.add {
        type = 'drop-down',
        name = 'sites',
    }
    mergeGroup.add {
        name = 'confirm',
        type = 'button',
        caption = { 'dqol-resource-monitor.ui-ok' },
        style = 'item_and_count_select_confirm',
        tags = {
            _module = 'site',
            _action = 'merge_confirm',
            site_id = site.id,
        }
    }

    local camera = inner.add {
        type = 'camera',
        position = { x = site.area.x, y = site.area.y },
        surface_index = site.surface,
        zoom = calculate_zoom(site),
        tooltip = { 'dqol-resource-monitor.ui-site-highlight-tooltip' },
        tags = {
            _module = 'site',
            _action = 'highlight',
            site_id = site.id,
        },
    }
    camera.style.size = 300
    camera.style.width = 392

    local table = outer.details.add { type = 'table', column_count = 2 }
    local stats = {
        {'amount', Util.Integer.toExponentString(site.calculated.amount, 2)},
        {'initial-amount', Util.Integer.toExponentString(site.initial_amount, 2)},
        {'percent', Util.Integer.toPercent(site.calculated.percent)},
        {'rate', Util.Integer.toExponentString(site.calculated.rate, 2) .. '/s'},
        {'estimated-depletion', Util.Integer.toTimeString(site.calculated.estimated_depletion, 'never')},
        {'created', Util.Integer.toTimeString(site.since) .. ' (' .. Util.Integer.toTimeString(game.tick - site.since) ..' ago)'},
        {'updated', Util.Integer.toTimeString(site.calculated.updated_at) .. ' (' .. Util.Integer.toTimeString(game.tick - site.calculated.updated_at) ..' ago)'},
        {'id', '#' .. site.id},
        {'surface', game.surfaces[site.surface].name .. ' [' .. site.surface .. ']'},
        {'tiles', Sites.site.getTiles(site)},
        {'chunks', table_size(site.chunks)},
    }
    for key, row in pairs(stats) do
        table.add {
            type = 'label',
            -- style = 'caption_label',
            caption = {'dqol-resource-monitor.ui-colon', {'dqol-resource-monitor.ui-site-' .. row[1]}},
        }
        table.add { type = 'label', caption = row[2]}
    end
end

---@returns LuaGuiElement
local function get_tab_from_event(event)
    ---@type LuaGuiElement
    local child = event.element
    local parent = child.parent

    while parent.type ~= 'tabbed-pane' do
        child = parent
        parent = child.parent
    end

    return child
end

---@param site Site
---@param player LuaPlayer
function UiSite.onRename(site, player, event)
    local tab = get_tab_from_event(event)
    local textfield = tab.main.site_outer.rename.textfield

    if textfield == nil then return end

    site.name = textfield.text

    Ui.Menu.show(player)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onRenameOpen(site, player, event)
    local tab = get_tab_from_event(event)
    local outer = tab.main.site_outer
    outer.title.visible = false
    outer.rename.visible = true

    local textfield = outer.rename.textfield
    if textfield == nil then return end
    textfield.focus()
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
    Ui.Menu.show(player)
end

function UiSite.onDeleteOpen(site, player, event)
    local tab = get_tab_from_event(event)
    local buttons = tab.main.site_outer.site.buttons

    if buttons == nil then return end

    if buttons.delete_open then buttons.delete_open.visible = false end
    if buttons.delete_confirm then buttons.delete_confirm.visible = true end

end

function UiSite.onDelete(site, player, event)
    if site ~= nil then
        Sites.storage.remove(site)
    end

    Ui.Menu.show(player)
end

---@param site Site
---@param player LuaPlayer
function UiSite.onToggleTracking(site, player, event)
    site.tracking = (site.tracking == false) or false

    -- immediately update the site
    Sites.updater.updateSite(site)

    Ui.Menu.show(player)
end

---@param site Site
---@return {site: Site, distance: double}[]
local function get_mergable_sites(site)
    -- all available of same type
    local types = Sites.storage.getSurfaceList()[site.surface] or {}
    local sites = {}

    for _, item in pairs(types[site.type] or {}) do
        if item.id ~= site.id then
            local distance = math.sqrt(math.pow(site.area.x - item.area.x, 2) + math.pow(site.area.y - item.area.y, 2))
            table.insert(sites, {site = item, distance = math.floor(distance)})
        end
    end

    -- sort by distance
    local function compare(siteA, siteB)
        return siteA.distance < siteB.distance
    end
    table.sort(sites, compare)
    
    return sites
end

---@param site Site
---@param player LuaPlayer
function UiSite.onMergeOpen(site, player, event)
    local tab = get_tab_from_event(event)
    local merge = tab.main.site_outer.site.merge
    if merge == nil then return end

    merge.visible = true
    local sites = get_mergable_sites(site)
    local items = {}
    local index = {}
    for _, item in pairs(sites) do
        table.insert(items, {'dqol-resource-monitor.ui-site-merge-select-item', item.site.id, item.site.name, item.distance})
        table.insert(index, item.site.id)
    end
    merge.sites.items = items
    local tags = merge.sites.tags
    tags.index = index
    merge.sites.tags = tags
end

---@param site Site
---@param player LuaPlayer
function UiSite.onMergeConfirm(site, player, event)
    local tab = get_tab_from_event(event)
    local merge = tab.main.site_outer.site.merge
    if merge == nil then return end

    local otherId = merge.sites.tags.index[merge.sites.selected_index] or nil
    local otherSite = otherId and Sites.storage.getById(otherId)

    if otherSite == nil then
        game.print('Failed to merge site #' .. (otherId or '') .. ' into #' .. site.id)
        return
    end

    -- do the merge
    Sites.merge(site, otherSite)
    Sites.storage.remove(otherSite)

    Ui.Menu.show(player)
end

return UiSite
