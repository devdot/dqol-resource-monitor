local UiMenu = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-menu',
    BUTTON_NAME = Ui.ROOT_FRAME .. '-menu-show',
    WINDOW_ID = 'menu',
    tabs = {
        sites = {},
        surfaces = {},
        dashboard = {},
        other = {},
    },
    filters = {},
    surfaces = {},
    dashboard = {},
}

---@param player LuaPlayer
function UiMenu.bootPlayer(player)
    UiMenu.createButton(player)
    UiMenu.close(player)
end

---@param player LuaPlayer
function UiMenu.createButton(player)
    local flow = Ui.mod_gui.get_button_flow(player)
    if flow[UiMenu.BUTTON_NAME] ~= nil then
        flow[UiMenu.BUTTON_NAME].destroy()
    end

    flow.add {
        type = 'sprite-button',
        name = UiMenu.BUTTON_NAME,
        tooltip = { 'dqol-resource-monitor.ui-menu-button-tooltip' },
        sprite = 'dqol-resource-monitor-logo',
        style = Ui.mod_gui.button_style,
        raise_hover_events = true,
        tags = {
            _module = 'menu',
            _action = 'toggle',
        }
    }
end

---@param player LuaPlayer
---@return WindowGui
function UiMenu.get(player)
    local window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    if window == nil then
        window = UiMenu.create(player)
    end
    return window
end

function UiMenu.isOpen(player)
    local window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    return window ~= nil
end

---@param player LuaPlayer
function UiMenu.close(player)
    Ui.Window.close(player, UiMenu.WINDOW_ID)
end

---@param player LuaPlayer
---@return WindowGui
function UiMenu.create(player)
    UiMenu.close(player)

    local window = Ui.Window.create(player, UiMenu.WINDOW_ID, { 'dqol-resource-monitor.ui-menu-title' })
    window.style.natural_width = 960
    window.style.maximal_width = 960
    window.style.natural_height = 880

    if window.titlebar ~= nil and window.titlebar.reload == nil then
        -- create the reload button
        window.titlebar.add {
            name = 'reload',
            index = #(window.titlebar.children),
            type = 'sprite-button',
            style = 'frame_action_button',
            sprite = 'utility/reset_white',
            tooltip = {'dqol-resource-monitor.ui-menu-reload-tooltip'},
            tags = {
                _module = 'menu',
                _action = 'show',
            },
        }
    end

    if window.inner ~= nil then window.inner.destroy() end
    local inner = window.add { name = 'inner', type = 'frame', style = 'inside_deep_frame' }
    local tabs = inner.add {
        name = 'tabbed',
        type = 'tabbed-pane',
        tags = {
            _module = 'menu',
            _action = 'tab_select',
            _only = defines.events.on_gui_selected_tab_changed,
        },
    }
    tabs.style.vertically_stretchable = true
    
    -- add all tabs here
    for name, object in pairs(UiMenu.tabs) do
        local caption = tabs.add { type = 'tab', caption = { 'dqol-resource-monitor.ui-menu-tab-' .. name } }
        local tab = tabs.add { name = name, type = 'flow', direction = 'vertical' }
        tabs.add_tab(caption, tab)
    end

    local state = Ui.State.get(player.index)

    state.menu.tab = state.menu.tab or 1
    tabs.selected_tab_index = state.menu.tab

    return window
end

---Display the main window
---@param player LuaPlayer
function UiMenu.show(player)
    UiMenu.fillCurrentTab(player)
end

---@param player LuaPlayer
function UiMenu.fillCurrentTab(player)
    local window = UiMenu.get(player)
    local tabs = window.inner.tabbed
    local index = tabs.selected_tab_index or 1
    local tab = tabs.tabs[index].content

    if table_size(tab.children) == 0 then
        -- empty tab, create first
        UiMenu.tabs[tab.name].create(tab)
    end

    UiMenu.tabs[tab.name].fill(tab)
end

---@param player LuaPlayer
---@param tabIndex integer
function UiMenu.switchToTab(player, tabIndex)
    local window = UiMenu.get(player)
    local tabs = window.inner.tabbed
    local tab = tabs.tabs[tabIndex] or nil

    if tab == nil then return end

    Ui.State.get(player.index).menu.tab = tabIndex
    tabs.selected_tab_index = tabIndex
end

---@param tab LuaGuiElement
function UiMenu.tabs.sites.create(tab)
    UiMenu.filters.create(tab, 'sites_filters')

    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    main.style.vertically_stretchable = true

    -- left side
    local sites_outer = main.add { name = 'sites_outer', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    sites_outer.style.width = 500
    sites_outer.style.natural_height = 600
    sites_outer.style.margin = 8
    sites_outer.style.vertically_stretchable = true
    local sites_header = sites_outer.add { type = 'flow', style = 'dqol_resource_monitor_table_row_flow' }
    sites_header.style.height = 28
    sites_header.style.width = 480
    sites_header.style.left_margin = 8
    sites_header.style.top_margin = 4
    sites_header.add { type = 'label', caption = '[img=utility/resource_editor_icon]', tooltip = {'dqol-resource-monitor.ui-site-type'}, style = 'dqol_resource_monitor_table_cell_resource' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-name]', tooltip = {'dqol-resource-monitor.ui-site-name'}, style = 'dqol_resource_monitor_table_cell_name' }
    sites_header.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-amount]', tooltip = {'dqol-resource-monitor.ui-site-amount'}, style = 'dqol_resource_monitor_table_cell_number' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-rate]', tooltip = {'dqol-resource-monitor.ui-site-rate'}, style = 'dqol_resource_monitor_table_cell_number' }
    sites_header.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-percent]', tooltip = {'dqol-resource-monitor.ui-site-percent'}, } 
    local sites = sites_outer.add { name = 'sites', type = 'scroll-pane' }
    sites.vertical_scroll_policy = 'always'
    sites.style.horizontally_stretchable = true
    sites.style.vertically_stretchable = true

    -- right side
    local site_outer = main.add {
        name = 'site_outer',
        type = 'frame',
        style = 'deep_frame_in_shallow_frame',
        direction = 'vertical',
    }
    site_outer.style.natural_width = 400
    site_outer.style.natural_height = 600
    site_outer.style.margin = 8
    site_outer.style.left_margin = 0
    site_outer.style.padding = 4
    site_outer.style.vertically_stretchable = true
    local site_title = site_outer.add { name = 'title', type = 'flow', direction = 'horizontal' }
    site_title.style.height = 26
    site_title.style.width = 392
    site_title.style.horizontally_stretchable = true
    site_title.style.vertical_align = 'center'
    local site_rename = site_outer.add { name = 'rename', type = 'flow', direction = 'horizontal', visible = false }
    site_rename.style.height = 26
    site_rename.style.width = 392
    site_rename.style.horizontally_stretchable = true
    site_rename.style.vertical_align = 'center'
    local site_inner = site_outer.add {name = 'site', type = 'flow', direction = 'vertical'}
    local site_details = site_outer.add { type = 'scroll-pane', name = 'details' }
    site_details.style.horizontally_stretchable = true
    site_details.style.vertically_stretchable = true
    site_details.vertical_scroll_policy = 'always'
    site_details.style.padding = 4
    site_details.style.left_margin = -4
    site_details.style.right_margin = -4
end

---@param tab LuaGuiElement
function UiMenu.tabs.sites.fill(tab)
    -- add filter with state
    local state = Ui.State.get(tab.player_index).menu.sites_filters
    UiMenu.filters.fill(tab, state, 'sites_filters')

    local sites = tab.main.sites_outer.sites
    sites.clear()

    -- fill sites
    local filteredSites = UiMenu.filters.getSites(state, Ui.State.get(tab.player_index).menu.use_products)
    local lastSurface = 0

    local showSurfaceSubheading = state.orderBy == nil and state.surface == nil and #game.surfaces > 1
    local appendSurfaceName = state.orderBy ~= nil and state.surface == nil and #game.surfaces > 1
    for key, site in pairs(filteredSites) do
        -- check if we should print the surface name
        if showSurfaceSubheading and lastSurface ~= site.surface then
            -- surface label row
            local row = sites.add { type = 'flow', style = 'dqol_resource_monitor_table_row_subheading' }

            lastSurface = site.surface
            -- row.add { type = 'label', caption = Surfaces.surface.getIconString(site.surface), style = 'dqol_resource_monitor_table_cell_resource'}
            row.add {
                type = 'label',
                style = 'caption_label',
                caption = Surfaces.surface.getNameById(site.surface)
            }
        end

        -- site row
        local row_button = sites.add {
            type = 'button',
            style = 'dqol_resource_monitor_table_row_button',
            tags = {
                _module = 'site',
                _action = 'show',
                site_id = site.id,
            },
        }

        local row = row_button.add { type = 'flow', style = 'dqol_resource_monitor_table_row_flow', ignored_by_interaction = true }
        local name = site.name
        if appendSurfaceName then
            name = { '', Surfaces.surface.getNameById(site.surface), ' ', name }
        end
        row.add { type = 'label', caption = Resources.getIconString(site.type), style = 'dqol_resource_monitor_table_cell_resource' }
        row.add { type = 'label', caption = name, style = 'dqol_resource_monitor_table_cell_name' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        row.add { type = 'label', caption = Util.Integer.toExponentString(site.calculated.amount, 2), style = 'dqol_resource_monitor_table_cell_number' }
        local rateString = (site.calculated.rate and Util.Integer.toExponentString(site.calculated.rate) .. '/s') or '-'
        row.add { type = 'label', caption = rateString, style = 'dqol_resource_monitor_table_cell_number' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local percentLabel = row.add { type = 'label', caption = Util.Integer.toPercent(site.calculated.percent) }
        percentLabel.style.font_color = Util.Integer.toColor(site.calculated.percent)
    end

    if #filteredSites == 0 then
        sites.add {
            type = 'label',
            caption = { 'dqol-resource-monitor.ui-menu-sites-empty' }
        }
    end


    -- fill site if set
    local state = Ui.State.get(tab.player_index)
    if state.menu.open_site_id then
        Ui.Site.showInMenu(state.menu.open_site_id, tab.main.site_outer)
    end
end

---@param tab LuaGuiElement
function UiMenu.tabs.surfaces.create(tab)
    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    main.style.horizontally_stretchable = true
    main.style.vertically_stretchable = true

    -- left side
    local surfaces_outer = main.add { name = 'surfaces_outer', type = 'frame', style = 'deep_frame_in_shallow_frame' }
    surfaces_outer.style.width = 500
    surfaces_outer.style.natural_height = 600
    surfaces_outer.style.margin = 8
    local surfaces = surfaces_outer.add { type = 'scroll-pane', name = 'surfaces' }
    surfaces.vertical_scroll_policy = 'always'
    surfaces.style.horizontally_stretchable = true
    surfaces.style.vertically_stretchable = true

    -- right side
    local surface_outer = main.add { name = 'surface_outer', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    surface_outer.style.minimal_width = 400
    surface_outer.style.natural_height = 600
    surface_outer.style.margin = 8
    surface_outer.style.left_margin = 0
    surface_outer.style.padding = 4
    surface_outer.style.vertically_stretchable = true
    local surface_title = surface_outer.add { type = 'flow', direction = 'horizontal', name = 'title' }
    surface_title.style.vertical_align = 'center'
    surface_title.add { type = 'sprite', name = 'icon', stretch_image_to_widget_size = true }.style.width = 32
    surface_title.add { type = 'label', name = 'title', style = 'heading_2_label', caption = '' }
    surface_title.style.bottom_margin = 4
    surface_outer.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }.style.bottom_margin = 4
    local surface = surface_outer.add { type = 'scroll-pane', name = 'surface' }
    surface.style.horizontally_stretchable = true
    surface.style.vertically_stretchable = true
    -- surface.vertical_scroll_policy = 'always'
end

---@param tab LuaGuiElement
function UiMenu.tabs.surfaces.fill(tab)
    local surfaces = tab.main.surfaces_outer.surfaces
    surfaces.clear()
    for index, surface in pairs(Surfaces.getVisibleSurfaces()) do
        local row_button = surfaces.add {
            type = 'button',
            style = 'dqol_resource_monitor_table_row_button',
            tags = {
                _module = 'surface',
                _action = 'show',
                surface_id = surface.id,
            },
        }
        
        local row = row_button.add{ type = 'flow', style = 'dqol_resource_monitor_table_row_flow', ignored_by_interaction = true }
        
        -- add resources
        local resources_string = ''
        for _, resource in pairs(surface.resources) do
            resources_string = resources_string .. Resources.getIconString(resource)
        end

        row.add { type = 'label', caption = Surfaces.surface.getName(surface), style = 'dqol_resource_monitor_table_cell_name' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local resources_label = row.add { type = 'label', caption = resources_string, style = 'dqol_resource_monitor_table_cell' }
        resources_label.style.width = 200
    end

    -- fill surface if set
    local state = Ui.State.get(tab.player_index)
    if state.menu.open_surface_id then
        Ui.Surface.showInMenu(state.menu.open_surface_id, tab.main.surface_outer)
    end
end

---@param tab LuaGuiElement
function UiMenu.tabs.dashboard.create(tab)
    UiMenu.filters.create(tab, 'dashboard_filters')

    tab.add { name = 'main', type = 'flow', direction = 'vertical'}
end

---@param tab LuaGuiElement
function UiMenu.tabs.dashboard.fill(tab)
    -- immediately update dashboard
    Ui.Dashboard.update(game.players[tab.player_index])

    -- add filter with state
    local state = Ui.State.get(tab.player_index)
    UiMenu.filters.fill(tab, state.menu.dashboard_filters, 'dashboard_filters')

    -- add dashboard data
    tab.main.clear()
    tab.main.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    local settings = tab.main.add { type = 'flow', direction = 'vertical' }
    settings.style.margin = 8


    local toggles = {
        'show_headers',
        'transparent_background',
    }

    for _, setting in pairs(toggles) do
        local localized = 'dqol-resource-monitor.ui-menu-dashboard-' .. string.gsub(setting, '_', '-')

        settings.add {
            type = 'checkbox',
            state = state.dashboard[setting] or false,
            caption = {localized},
            tooltip = {localized .. '-tooltip'},
            tags = {
                _module = 'menu_dashboard',
                _action = 'toggle_setting',
                _only = defines.events.on_gui_checked_state_changed,
                setting = setting,
            }
        }
    end

    local selects = {
        mode = {
            'always',
            'hover',
            'never',
        },
        prepend_surface = {
            'name',
            'icon',
            'none',
        },
    }

    for setting, options in pairs(selects) do
        local localized = 'dqol-resource-monitor.ui-menu-dashboard-' .. string.gsub(setting, '_', '-')
        
        local items = {}
        local reversed = {}
        for _, item in pairs(options) do 
            table.insert(items, {localized .. '-option-' .. item})
            reversed[item] = #items
        end
        
        settings.add { type = 'label', caption = { localized }, tooltip = { localized .. '-tooltip'} }
        settings.add {
            type = 'drop-down',
            name = setting,
            tooltip = { localized .. '-tooltip'},
            items = items,
            selected_index = reversed[state.dashboard[setting]] or nil,
            tags = {
                _module = 'menu_dashboard',
                _action = 'select_setting',
                _only = defines.events.on_gui_selection_state_changed,
                index = options,
                setting = setting,
            },
        }
    end
end

---@param tab LuaGuiElement
function UiMenu.tabs.other.create(tab)
end

---@param tab LuaGuiElement
function UiMenu.tabs.other.fill(tab)
    tab.clear()

    local info = tab.add { type = 'table', column_count = 2 }
    info.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-other-info-headline'}, style = 'caption_label' }
    info.add { type = 'label', caption = '' }
    
    if storage.sites and storage.sites.updater then
        local queueLength = #storage.sites.updater.queue
        local chunksPerUpdate = settings.global['dqol-resource-monitor-site-chunks-per-update'].value
        local ticksBetweenUpdates = settings.global['dqol-resource-monitor-site-ticks-between-updates'].value
        local ticksToFinishQueue = ticksBetweenUpdates * (queueLength + 1)
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-length' } }
        info.add { type = 'label', caption = queueLength }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-position' } }
        info.add { type = 'label', caption = storage.sites.updater.pointer }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-total-chunks' } }
        info.add { type = 'label', caption = ((queueLength - 1) * chunksPerUpdate) + (#(storage.sites.updater.queue[#storage.sites.updater.queue] or {})) }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-chunks-per-update' } }
        info.add { type = 'label', caption = chunksPerUpdate }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-ticks-between-updates' } }
        info.add { type = 'label', caption = ticksBetweenUpdates }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-duration' } }
        info.add { type = 'label', caption = Util.Integer.toTimeString(ticksToFinishQueue) .. ' (' .. ticksToFinishQueue .. ')' }
    else
        info.add { type = 'label', caption = 'Updater is not initialized yet. If the mod was just loaded, you may need to wait a little. Otherwise, check that there are sites with tracking enabled.' }
        info.add { type = 'label', caption = '' }
    end
    
    tab.add { type = 'line' }
    tab.add {
        type = 'switch',
        switch_state = (Ui.State.get(tab.player_index).menu.use_products and 'right') or 'left',
        allow_none_state = false,
        right_label_caption = {'dqol-resource-monitor.ui-menu-other-use-products-switch-products'},
        right_label_tooltip = {'dqol-resource-monitor.ui-menu-other-use-products-switch-products-tooltip'},
        left_label_caption = {'dqol-resource-monitor.ui-menu-other-use-products-switch-resources'},
        left_label_tooltip = {'dqol-resource-monitor.ui-menu-other-use-products-switch-resources-tooltip'},
        tags = {
            _module = 'menu',
            _action = 'use_products_toggle',
        }
    }
    
    tab.add { type = 'line' }
    tab.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-other-types-label'}, style = 'info_label' }
    local scroll = tab.add { type = 'scroll-pane' }
    local table = scroll.add { type = 'table', column_count = 7 }
    table.add { type = 'label', caption = 'resource name' }
    table.add { type = 'label', caption = 'category' }
    table.add { type = 'label', caption = 'infinite' }
    table.add { type = 'label', caption = 'hidden' }
    table.add { type = 'label', caption = 'ignore tracking' }
    table.add { type = 'label', caption = 'loose merge' }
    table.add { type = 'label', caption = 'products' }

    local toggles = {'infinite', 'hidden', 'tracking_ignore', 'loose_merge'}

    for _, type in pairs(Resources.types) do
        table.add { type = 'label', caption = type.resource_name }
        table.add { type = 'label', caption = type.category }
        
        for _, toggle in pairs(toggles) do
            table.add {
                type = 'checkbox',
                state = type[toggle],
                tags = {
                    _module = 'menu',
                    _action = 'toggle_resource_type_setting',
                    resource_name = type.resource_name,
                    setting = toggle,
                }
            }
        end

        local products = ''
        for __, product in pairs(Resources.getProducts(type.resource_name)) do
            products = products .. ' ' .. product.name
        end
        table.add { type = 'label', caption = products }
    end
end

function UiMenu.onUseProductsToggle(event)
    local toggle = event.element.switch_state == 'right'
    Ui.State.get(event.player_index).menu.use_products = toggle
    UiMenu.create(game.players[event.player_index])
    UiMenu.show(game.players[event.player_index])
end

---@param tab LuaGuiElement
---@param filter_group 'sites_filters'|'dashboard_filters'
function UiMenu.filters.create(tab, filter_group)
    local filters = tab.add { name = 'filters', type = 'flow', direction = 'vertical' }
    filters.style.margin = 8
    filters.style.vertical_spacing = 2

    local state = Ui.State.get(tab.player_index)

    -- make resource filter
    local useProductsForFilter = state.menu.use_products or false
    local items = (useProductsForFilter and Resources.cleanProducts()) or Resources.cleanResources()
    local resourcesFilter = filters.add {
        name = 'resources',
        type = 'table',
        style = 'compact_slot_table',
        column_count = math.min(24, table_size(items)) + 1,
        tags = {
            use_products = useProductsForFilter
        },
    }

    ---@type {toggled: boolean, sprite: string, tooltip: string, filter_name: string}[]
    local data = {}
    for _, item in pairs(items) do
        if useProductsForFilter then
            table.insert(data, {
                sprite = item.type .. '/' .. item.name,
                tooltip = item.type .. '-name.' .. item.name,
                filter_name = item.name,
            })
        else
            table.insert(data, {
                sprite = Resources.getSpriteString(item.resource_name),
                tooltip = 'entity-name.' .. item.resource_name,
                filter_name = item.resource_name,
            })
        end
    end

    for key, item in pairs(data) do
        resourcesFilter.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            toggled = false,
            sprite = item.sprite,
            tooltip = { 'dqol-resource-monitor.ui-menu-filter-resource-tooltip', { item.tooltip } },
            tags = {
                _module = 'menu_filters',
                _action = 'toggle_resource',
                filter_group = filter_group,
                resource_name = item.filter_name,
            }
        }
    end
    
    local resourcesReset = resourcesFilter.add {
        name = 'reset',
        type = 'sprite-button',
        style = 'red_button',
        sprite = 'utility/reset',
        tooltip = { 'dqol-resource-monitor.ui-menu-filter-resource-reset-tooltip' },
        tags = {
            _module = 'menu_filters',
            _action = 'toggle_resource',
            filter_group = filter_group,
            reset = true,
        },
    }
    resourcesReset.style.size = 36

    -- row 2
    local textGroup = filters.add { name = 'textGroup', type = 'table', column_count = 5, style = 'slot_table' }
    textGroup.style.horizontal_spacing = 40
    textGroup.style.vertical_align = 'center'
    textGroup.style.horizontally_stretchable = true

    local textFilters = {
        {
            name = 'maxPercent',
            sprite = 'dqol-resource-monitor-filter-percent',
            filter = 'max-percent',
            action = 'set_max_percent',
            numeric = true,
        },
        {
            name = 'maxEstimatedDepletion',
            sprite = 'dqol-resource-monitor-filter-depletion',
            filter = 'max-estimated-depletion',
            action = 'set_max_estimated_depletion',
            numeric = true,
        },
        {
            name = 'minAmount',
            sprite = 'dqol-resource-monitor-filter-amount',
            filter = 'min-amount',
            action = 'set_min_amount',
            numeric = true,
            width = 74,
        },
        {
            name = 'search',
            sprite = 'utility/search',
            filter = 'search',
            action = 'set_search',
            numeric = false,
            allow_decimal = true,
            allow_negative = true,
            width = 150,
        },
    }

    for _, item in pairs(textFilters) do
        local group = textGroup.add {
            name = item.name,
            type = 'flow',
            direction = 'horizontal',
        }
        group.style.vertical_align = 'center'
        group.style.horizontal_spacing = 2

        group.add {
            type = 'sprite-button',
            enabled = false,
            sprite = item.sprite,
            style = 'compact_slot_sized_button',
            tooltip = {'dqol-resource-monitor.ui-menu-filter-' .. item.filter ..'-tooltip'},
        }
        local field = group.add {
            type = 'textfield',
            name = item.name,
            text = '',
            numeric = item.numeric or false,
            allow_decimal = item.allow_decimal or false,
            allow_negative = item.allow_negative or false,
            lose_focus_on_confirm = true,
            style = 'very_short_number_textfield',
            tooltip = {'dqol-resource-monitor.ui-menu-filter-' .. item.filter ..'-tooltip'},
            tags = {
                _module = 'menu_filters',
                _action = item.action,
                _only = defines.events.on_gui_confirmed,
                filter_group = filter_group,
            },
        }
        field.style.height = 34
        field.style.width = item.width or 36
    end

    -- generate surfaces
    local surfaces = {{'dqol-resource-monitor.ui-menu-filter-surface-all'}}
    local selectToSurfaceId = {nil}
    local surfaceIdToSelect = {}
    for _, surface in pairs(Surfaces.getVisibleSurfaces()) do
        table.insert(surfaces, Surfaces.surface.getName(surface))
        table.insert(selectToSurfaceId, #surfaces, surface.id)
        table.insert(surfaceIdToSelect, surface.id, #surfaces)
    end

    local surfaceSelect = textGroup.add {
        name = 'surface',
        visible = #surfaces > 2,
        type = 'drop-down',
        items = surfaces,
        tooltip = {'dqol-resource-monitor.ui-menu-filter-surface-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'select_surface',
            _only = defines.events.on_gui_selection_state_changed,
            filter_group = filter_group,
            selectToSurfaceId = selectToSurfaceId,
            surfaceIdToSelect = surfaceIdToSelect,
        },
    }
    surfaceSelect.style.height = 36
    surfaceSelect.style.width = 150

    local orderAndStateFilter = filters.add { name = 'orderAndState', type = 'flow', direction = 'horizontal' }
    orderAndStateFilter.style.horizontally_squashable = true
    orderAndStateFilter.style.horizontal_spacing = 2

    local orderBy = {
        { value = nil },
        { value = 'resource' },
        { value = 'name' },
        { value = 'amount' },
        { value = 'percent' },
        { value = 'rate' },
        { value = 'depletion' },
    }
    local orderByFilter = orderAndStateFilter.add {
        type = 'table',
        name = 'orderBy',
        style = 'compact_slot_table',
        column_count = #orderBy,
    }

    for _, item in pairs(orderBy) do
        orderByFilter.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            toggled = false,
            tags = {
                _module = 'menu_filters',
                _action = 'set_order_by',
                filter_group = filter_group,
                order_by = item.value,
                order_by_direction = 'asc',
            }
        }
    end

    local stateFiller = orderAndStateFilter.add { type = 'flow', direction = 'horizontal' }
    -- stateFiller.style.horizontally_stretchable = true
    -- stateFiller.style.horizontally_squashable = true;
    stateFiller.style.width = 112

    local stateFilter = orderAndStateFilter.add { name = 'states', type = 'table', column_count = 2, style = 'compact_slot_table' }
    stateFilter.add {
        type = 'sprite-button',
        name = 'onlyTracked',
        toggled = false,
        style = 'slot_sized_button_blue',
        sprite = 'dqol-resource-monitor-site-track',
        tooltip = {'dqol-resource-monitor.ui-menu-filter-only-tracked-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'toggle_only_tracked',
            filter_group = filter_group,
        },
    }.style.size = 36
    stateFilter.add {
        type = 'sprite-button',
        name = 'onlyEmpty',
        toggled = false,
        style = 'compact_slot_sized_button',
        sprite = 'utility/resources_depleted_icon',
        tooltip = {'dqol-resource-monitor.ui-menu-filter-only-empty-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'toggle_only_empty',
            filter_group = filter_group,
        }
    }
end

---@param tab LuaGuiElement
---@param state UiStateMenuFilter
---@param filter_group 'sites_filters'|'dashboard_filters'
function UiMenu.filters.fill(tab, state, filter_group)
    local filters = tab.filters

    -- resources
    local resourcesFilter = filters.resources
    for _, item in pairs(resourcesFilter.children) do
        item.toggled = state.resources[item.tags.resource_name] ~= nil
    end
    resourcesFilter.reset.visible = table_size(state.resources) > 0

    -- surface select
    local surfaceFilter = filters.textGroup.surface
    if surfaceFilter.visible then
        local surfaceIndex = surfaceFilter.tags.surfaceIdToSelect['' .. (state.surface or '')] or 1
        surfaceFilter.selected_index = surfaceIndex
    end

    -- text fields
    filters.textGroup.maxPercent.maxPercent.text = (state.maxPercent or 100) .. ''
    filters.textGroup.maxEstimatedDepletion.maxEstimatedDepletion.text = ((state.maxEstimatedDepletion and (state.maxEstimatedDepletion / (60 * 60 * 60))) or '') .. '' -- convert from ticks to hours
    filters.textGroup.minAmount.minAmount.text = math.floor(state.minAmount / 1000) .. '' -- convert to k
    filters.textGroup.search.search.text = state.search or ''
    
    -- state
    filters.orderAndState.states.onlyTracked.toggled = state.onlyTracked or false
    filters.orderAndState.states.onlyEmpty.toggled = state.onlyEmpty or false

    -- order by
    for _, item in pairs(filters.orderAndState.orderBy.children) do
        local name = item.tags.order_by or 'default'
        local toggled = (state.orderBy or 'default') == name
        local direction = 'asc'
        local hoverDirection = 'asc'
        if toggled then
            -- check for the state to find direction
            if state.orderByDesc == true then
                direction = 'desc'
            end

            hoverDirection = (state.orderByDesc and 'asc') or 'desc'
        end

        item.toggled = toggled
        item.sprite = 'dqol-resource-monitor-filter-' .. name .. '-' .. direction
        -- item.hovered_sprite = 'dqol-resource-monitor-filter-' .. name .. '-' .. hoverDirection
        item.tooltip = { 'dqol-resource-monitor.ui-menu-filter-order-by', {'dqol-resource-monitor.ui-menu-filter-order-' .. name}, {'dqol-resource-monitor.ui-menu-filter-order-by-' .. hoverDirection} }
        
        local tags = item.tags
        tags.order_by_direction = hoverDirection
        item.tags = tags
    end
end

---@param state UiStateMenuFilter
---@param use_products? boolean
---@return Site[]
function UiMenu.filters.getSites(state, use_products)
    local filterSurface = state.surface ~= nil
    local filterResources = table_size(state.resources) > 0
    use_products = use_products or false

    ---@type Site[]
    local sites = {}

    for surfaceId, types in pairs(Sites.storage.getSurfaceList()) do
        -- filter for surface type
        if filterSurface == false or state.surface == surfaceId then
            for type, typeSites in pairs(types) do
                -- filter for resource type
                local allowType = false
                if not use_products then
                    allowType = state.resources[type] ~= nil
                else
                    for _, key in pairs(Resources.types[type].products) do
                        if state.resources[key] ~= nil then
                            allowType = true
                        end
                    end
                end
                if filterResources == false or allowType then
                    for key, site in pairs(typeSites) do
                        -- legacy, deal with missing computed on sites
                        if site.calculated == nil then
                            Sites.site.updateCalculated(site)
                        end

                        local insert = true
                        if state.onlyTracked == true and site.tracking == false then
                            insert = false
                        elseif state.onlyEmpty == true and site.calculated.amount > 0 then
                            insert = false
                        elseif (site.calculated.percent) * 100 > (state.maxPercent or 100) then
                            insert = false
                        elseif state.maxEstimatedDepletion and (site.calculated.estimated_depletion == nil or site.calculated.estimated_depletion > state.maxEstimatedDepletion) then
                            insert = false
                        elseif state.minAmount > site.calculated.amount then
                            insert = false
                        elseif state.search ~= nil and string.find(string.lower(site.name), string.lower(state.search)) == nil then
                            insert = false
                        end

                        if insert then
                            table.insert(sites, site)
                        end
                    end
                end
            end
        end
    end

    -- deal with ordering
    if state.orderBy == 'resource' then
        local function compare(siteA, siteB)
            return siteA.type < siteB.type
        end
        table.sort(sites, compare)
    elseif state.orderBy == 'name' then
        local function compare(siteA, siteB)
            return siteA.name < siteB.name
        end
        table.sort(sites, compare)
    elseif state.orderBy == 'amount' then
        local function compare(siteA, siteB)
            return siteA.calculated.amount < siteB.calculated.amount
        end
        table.sort(sites, compare)
    elseif state.orderBy == 'percent' then
        local function compare(siteA, siteB)
            return siteA.calculated.percent < siteB.calculated.percent
        end
        table.sort(sites, compare)
    elseif state.orderBy == 'rate' then
        local function compare(siteA, siteB)
            return siteA.calculated.rate < siteB.calculated.rate
        end
        table.sort(sites, compare)
    elseif state.orderBy == 'depletion'then
        local function compare(siteA, siteB)
            return (siteA.calculated.estimated_depletion or 1000000000) < (siteB.calculated.estimated_depletion or 1000000000)
        end
        table.sort(sites, compare)
    end

    if state.orderByDesc then
        -- quick reverse
        for i = 1, math.floor(#sites/2), 1 do
            sites[i], sites[#sites-i+1] = sites[#sites-i+1], sites[i]
        end
    end

    return sites
end

function UiMenu.onShow(event)
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.onToggle(event)
    local player = game.players[event.player_index]

    if event.name == defines.events.on_gui_click then
        if UiMenu.isOpen(player) then
            UiMenu.close(player)
        else
            UiMenu.show(player)
        end
    else
        local state = Ui.State.get(event.player_index)
        if state.dashboard.mode == 'hover' then
            state.dashboard.is_hovering = event.name == defines.events.on_gui_hover
            Ui.Dashboard.fill(player)
        end
    end
end


function UiMenu.onSelectedTabChanged(event)
    UiMenu.switchToTab(game.players[event.player_index], event.element.selected_tab_index or 1)
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.onSiteShow(site, player)
    Ui.State.get(player.index).menu.open_site_id = site.id
    UiMenu.switchToTab(player, 1)
    UiMenu.show(player)
end


---@param surface Surface
---@param player LuaPlayer
function UiMenu.onSurfaceShow(surface, player)
    Ui.State.get(player.index).menu.open_surface_id = surface.id
    UiMenu.switchToTab(player, 2)
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onToggleResource(event, player, state)
    if event.element.tags.reset == true then
        state.resources = {}
    else
        local resource = event.element.tags.resource_name
        if state.resources[resource] == nil then
            state.resources[resource] = true
        else
            state.resources[resource] = nil
        end
    end

    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSelectSurface(event, player, state)
    if event.element.tags.reset == nil then
        state.surface = (event.element.tags.selectToSurfaceId and event.element.tags.selectToSurfaceId[event.element.selected_index .. '']) or nil
    else
        state.surface = nil
    end

    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onToggleOnlyTracked(event, player, state)
    state.onlyTracked = state.onlyTracked == false
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onToggleOnlyEmpty(event, player, state)
    state.onlyEmpty = state.onlyEmpty == false
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetMaxPercent(event, player, state)
    state.maxPercent = tonumber(event.element.text) or 100
    if state.maxPercent > 100 then state.maxPercent = 100 end
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetMaxEstimatedDepletion(event, player, state)
    if event.element.text == '' then
        state.maxEstimatedDepletion = nil
    else
        state.maxEstimatedDepletion = tonumber(event.element.text) * 60 * 60 * 60 -- store in ticks
        if state.maxEstimatedDepletion < 0 then state.maxEstimatedDepletion = 0 end
    end
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetMinAmount(event, player, state)
    state.minAmount = tonumber(event.element.text) or 0
    state.minAmount = state.minAmount * 1000
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetSearch(event, player, state)
    state.search = event.element.text
    if state.search == '' then state.search = nil end
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetOrderBy(event, player, state)
    state.orderBy = event.element.tags.order_by
    state.orderByDesc = event.element.tags.order_by_direction == 'desc'
    UiMenu.show(player)
end

---@param state UiStateDashboard
function UiMenu.dashboard.onToggleSetting(event, state)
    state[event.element.tags.setting] = event.element.state
    UiMenu.show(game.players[event.player_index])
end

---@param state UiStateDashboard
function UiMenu.dashboard.onSelectSetting(event, state)
    local select = event.element
    state[select.tags.setting] = select.tags.index[select.selected_index]
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.onToggleResourceTypeSetting(event)
    local player = game.players[event.player_index]
    local tags = event.element.tags
    
    -- change that setting
    local type = Resources.types[tags.resource_name] or nil
    if type == nil or type[tags.setting] == nil then return end
    type[tags.setting] = event.element.state or false

    UiMenu.create(player)
    UiMenu.show(player)
end

return UiMenu
