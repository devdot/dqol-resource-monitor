local UiMenu = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-menu',
    BUTTON_NAME = Ui.ROOT_FRAME .. '-menu-show',
    WINDOW_ID = 'menu',
    tabs = {},
    filters = {},
    surfaces = {},
    dashboard = {},
}

---@param LuaPlayer
function UiMenu.bootPlayer(player)
    UiMenu.createButton(player)
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
        sprite = 'item/rocket-control-unit',
        style = Ui.mod_gui.button_style,
        tags = {
            _module = 'menu',
            _action = 'show',
        }
    }
end

---Display the main window
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiMenu.show(player, window)
    if window == nil then
        window = Ui.Window.create(player, UiMenu.WINDOW_ID, { 'dqol-resource-monitor.ui-menu-title' })
    end

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
    
    -- add all tabs here
    for name, func in pairs(UiMenu.tabs) do
        local caption = tabs.add { type = 'tab', caption = { 'dqol-resource-monitor.ui-menu-tab-' .. name } }
        local tab = tabs.add { name = name, type = 'flow', direction = 'vertical' }
        func(tab)
        tabs.add_tab(caption, tab)
    end

    tabs.selected_tab_index = Ui.State.get(player.index).menu.tab or 1
end

function UiMenu.tabs.sites(tab)
    -- add filter with state
    local state = Ui.State.get(tab.player_index).menu.sites_filters
    UiMenu.filters.add(tab, state, 'sites_filters')

    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    
    -- left side
    local sites_frame = main.add { name = 'sites', type = 'frame', style = 'deep_frame_in_shallow_frame' }
    sites_frame.style.width = 450
    sites_frame.style.natural_height = 600
    sites_frame.style.margin = 8
    local sites_scroll = sites_frame.add { type = 'scroll-pane' }
    sites_scroll.vertical_scroll_policy = 'always'
    sites_scroll.style.horizontally_stretchable = "stretch_and_expand"
    sites_scroll.style.vertically_stretchable = "stretch_and_expand"
    local sites = sites_scroll.add { name = 'sites', type = 'flow', direction = 'vertical' }

    -- right side
    local preview = main.add { name = 'preview', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    preview.style.natural_width = 400
    preview.style.natural_height = 600
    preview.style.margin = 8
    preview.style.left_margin = 0
    preview.style.padding = 4

    -- fill sites
    local filteredSites = UiMenu.filters.getSites(state)
    local lastSurface = 0
    for key, site in pairs(filteredSites) do
        -- check if we should print the surface name
        if lastSurface ~= site.surface then
            -- surface label row
            local row = sites.add { type = 'flow', style = 'dqol_resource_monitor_table_row_subheading' }

            lastSurface = site.surface
            row.add {
                type = 'label',
                style = 'caption_label',
                caption = game.surfaces[site.surface].name
            }
        end

        -- site row
        local row_button = sites.add {
            type = 'button',
            style = 'dqol_resource_monitor_table_row_button',
            tags = {
                _module = 'menu_site',
                _action = 'show',
                site_id = site.id,
            },
        }
        
        local row = row_button.add{ type = 'flow', style = 'dqol_resource_monitor_table_row_flow', ignored_by_interaction = true }
        local type = Resources.types[site.type]
        row.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']', style = 'dqol_resource_monitor_table_cell_resource' }
        row.add { type = 'label', caption = site.name, style = 'dqol_resource_monitor_table_cell_name' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        row.add { type = 'label', caption = Util.Integer.toExponentString(site.amount), style = 'dqol_resource_monitor_table_cell_number' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local percentLabel = row.add { type = 'label', caption = Util.Integer.toPercent(site.amount / site.initial_amount) }
        percentLabel.style.font_color = Util.Integer.toColor(site.amount / site.initial_amount)
    end
    
    if #filteredSites == 0 then
        sites_frame.add {
            type = 'label',
            caption = {'dqol-resource-monitor.ui-menu-sites-empty'}
        }
    end
end

function UiMenu.tabs.surfaces(tab)
    local types = Resources.clean{withoutSECore = true}
    local table = tab.add {
        type = 'table',
        column_count = 3 + table_size(types),
    }

    -- do the headers
    table.add { type = 'label', style = 'caption_label', caption = { 'dqol-resource-monitor.ui-menu-surfaces-name' } }
    table.add { type = 'label', style = 'caption_label', caption = { 'dqol-resource-monitor.ui-menu-surfaces-chunks' } }
    for _, type in pairs(types) do
        table.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']' }
    end
    table.add { type = 'label', caption = '' }

    -- gather data
    local scanCache = Scanner.cache.get()
    local allSites = Sites.storage.getSurfaceList()

    -- fill the surfaces
    for key, surface in pairs(game.surfaces) do
        table.add { type = 'label', caption = surface.name }
        table.add { type = 'label', caption = table_size(scanCache.chunks[surface.index] or {}) }
        
        if allSites[surface.index] ~= nil then
            for _, type in pairs(types) do
                local sum = 0
                for __, site in pairs(allSites[surface.index][type.resource_name] or {}) do
                    sum = sum + site.amount
                end
                table.add { type = 'label', caption = (sum > 0 and Util.Integer.toExponentString(sum)) or '' }
            end
        else
            for _, type in pairs(types) do
                table.add { type = 'label', caption = '' }
            end
        end

        local buttons = table.add { type = 'table', style = 'compact_slot_table', column_count = 5 }
        buttons.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            tooltip = { 'dqol-resource-monitor.ui-menu-surfaces-scan-tooltip' },
            sprite = 'utility/reset',
            tags = {
                _module = 'menu_surfaces',
                _action = 'scan',
                surfaceId = surface.index,
            },
        }
        buttons.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            tooltip = { 'dqol-resource-monitor.ui-menu-surfaces-auto-track-tooltip' },
            sprite = 'item/electric-mining-drill',
            tags = {
                _module = 'menu_surfaces',
                _action = 'auto_track',
                surfaceId = surface.index,
            },
        }
        buttons.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            tooltip = { 'dqol-resource-monitor.ui-menu-surfaces-track-all-tooltip' },
            sprite = 'utility/check_mark',
            tags = {
                _module = 'menu_surfaces',
                _action = 'track_all',
                surfaceId = surface.index,
            },
        }
        buttons.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            tooltip = { 'dqol-resource-monitor.ui-menu-surfaces-untrack-all-tooltip' },
            sprite = 'utility/close_black',
            tags = {
                _module = 'menu_surfaces',
                _action = 'untrack_all',
                surfaceId = surface.index,
            },
        }
        buttons.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            tooltip = {'dqol-resource-monitor.ui-menu-surfaces-reset-tooltip'},
            sprite = 'utility/trash',
            tags = {
                _module = 'menu_surfaces',
                _action = 'reset',
                surfaceId = surface.index,
            },
        }
    end
end

function UiMenu.tabs.dashboard(tab)
    local note = tab.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-dashboard-note' } }
    note.style.margin = 8

    -- add filter with state
    local state = Ui.State.get(tab.player_index)
    UiMenu.filters.add(tab, state.menu.dashboard_filters, 'dashboard_filters')

    tab.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    local settings = tab.add { type = 'flow', direction = 'vertical' }
    settings.style.margin = 8

    settings.add {
        type = 'checkbox',
        state = state.dashboard.show_headers or false,
        caption = {'dqol-resource-monitor.ui-menu-dashboard-show-headers'},
        tooltip = {'dqol-resource-monitor.ui-menu-dashboard-show-headers-tooltip'},
        tags = {
            _module = 'menu_dashbaord',
            _action = 'toggle_value',
            _only = defines.events.on_gui_checked_state_changed,
            state_key = 'show_headers',
        }
    }
    settings.add {
        type = 'checkbox',
        state = state.dashboard.prepend_surface_name or false,
        caption = {'dqol-resource-monitor.ui-menu-dashboard-prepend-surface-name'},
        tooltip = {'dqol-resource-monitor.ui-menu-dashboard-prepend-surface-name-tooltip'},
        tags = {
            _module = 'menu_dashbaord',
            _action = 'toggle_value',
            _only = defines.events.on_gui_checked_state_changed,
            state_key = 'prepend_surface_name',
        }
    }
end

function UiMenu.tabs.other(tab)
    tab.add { type = 'label', caption = 'other' }

    local buttons = tab.add { name = 'buttons', type = 'frame', style = 'slot_button_deep_frame', direction = 'horizontal' }
    buttons.style.margin = 8
    buttons.add {
        type = 'button',
        style = 'slot_button',
        caption = 'test',
    }

    if _DEBUG then
        local table = tab.add { type = 'table', column_count = 3 }
        for _, type in pairs(Resources.types) do
            table.add { type = 'label', caption = type.name }
            table.add { type = 'label', caption = type.type }
            table.add { type = 'label', caption = type.resource_name }
        end
    end
end

---@param player LuaPlayer
---@return LuaGuiElement?
function UiMenu.getPreview(player)
    local window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    if window == nil then
        UiMenu.show(player)
        window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    end

    if window == nil then return nil end
    if window['inner'] == nil or window['inner']['tabbed'] == nil then return nil end -- todo change this
    return window['inner']['tabbed']['sites']['main']['preview'] or nil
end

---@param tab LuaGuiElement
---@param state UiStateMenuFilter
---@param filter_group 'sites_filters'|'dashboard_filters'
function UiMenu.filters.add(tab, state, filter_group)
    local filterGroup = tab.add { type = 'flow', direction = 'vertical', }
    filterGroup.style.margin = 8

    local showResourceFilterReset = table_size(state.resources) > 0
    local resources = Resources.clean()
    local resourceFilter = filterGroup.add {
        name = 'filters',
        type = 'table',
        style = 'compact_slot_table',
        column_count = table_size(resources) + ((showResourceFilterReset and 1) or 0),
    }

    for key, resource in pairs(resources) do
        resourceFilter.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            toggled = state.resources[resource.resource_name] ~= nil,
            sprite = resource.type .. '/' .. resource.name,
            tooltip = { 'dqol-resource-monitor.ui-menu-filter-resource-tooltip', { resource.type .. '-name.' .. resource.name }},
            tags = {
                _module = 'menu_filters',
                _action = 'toggle_resource',
                filter_group = filter_group,
                resource_name = resource.resource_name,
            }
        }
    end
    -- add reset button if needed
    if showResourceFilterReset then
        local reset = resourceFilter.add {
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
        reset.style.size = 36
    end

    -- generate surfaces
    local surfaces = {}
    for index, surface in pairs(game.surfaces) do table.insert(surfaces, surface.name) end

    local surfaceFilter = filterGroup.add { type = 'flow', direction = 'horizontal' }
    local surfaceIndex = state.surface or nil
    if surfaces[surfaceIndex] == nil then surfaceIndex = nil end
    local surfaceSelect = surfaceFilter.add {
        name = 'surface',
        type = 'drop-down',
        items = surfaces,
        selected_index = surfaceIndex,
        tooltip = {'dqol-resource-monitor.ui-menu-filter-surface-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'select_surface',
            _only = defines.events.on_gui_selection_state_changed,
            filter_group = filter_group,
        },
    }
    -- show reset button if needed
    if state.surface ~= nil then
        surfaceFilter.add {
            type = 'sprite-button',
            style = 'tool_button_red',
            sprite = 'utility/reset',
            tooltip = {'dqol-resource-monitor.ui-menu-filter-surface-reset-tooltip'},
            tags = {
                _module = 'menu_filters',
                _action = 'select_surface',
                filter_group = filter_group,
                reset = true,
            },
        }
    end

    local percentFilter = filterGroup.add { type = 'flow', direction = 'horizontal' }
    percentFilter.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-filter-max-percent'}}
    percentFilter.add {
        type = 'textfield',
        text = state.maxPercent or 100,
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        lose_focus_on_confirm = true,
        style = 'very_short_number_textfield',
        tags = {
            _module = 'menu_filters',
            _action = 'set_max_percent',
            _only = defines.events.on_gui_confirmed,
            filter_group = filter_group,
        },
    }
    percentFilter.add { type = 'label', caption = '%' }
    
    local searchFilter = filterGroup.add { type = 'flow', direction = 'horizontal' }
    searchFilter.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-filter-search' } }
    searchFilter.add {
        type = 'textfield',
        text = state.search or '',
        lose_focus_on_confirm = true,
        tags = {
            _module = 'menu_filters',
            _action = 'set_search',
            _only = defines.events.on_gui_confirmed,
            filter_group = filter_group,
        },
    }

    local stateFilter = filterGroup.add { type = 'flow', direction = 'horizontal' }
    stateFilter.add {
        type = 'checkbox',
        state = state.onlyTracked or false,
        caption = {'dqol-resource-monitor.ui-menu-filter-only-tracked'},
        tooltip = {'dqol-resource-monitor.ui-menu-filter-only-tracked-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'toggle_only_tracked',
            _only = defines.events.on_gui_checked_state_changed,
            filter_group = filter_group,
        },
    }
    stateFilter.add {
        type = 'checkbox',
        state = state.onlyEmpty or false,
        caption = {'dqol-resource-monitor.ui-menu-filter-only-empty'},
        tooltip = {'dqol-resource-monitor.ui-menu-filter-only-empty-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'toggle_only_empty',
            _only = defines.events.on_gui_checked_state_changed,
            filter_group = filter_group,
        }
    }    
end

---@param state UiStateMenuFilter
---@return Site[]
function UiMenu.filters.getSites(state)
    local filterSurface = state.surface ~= nil
    local filterResources = table_size(state.resources) > 0

    ---@type Site[]
    local sites = {}

    for surfaceId, types in pairs(Sites.storage.getSurfaceList()) do
        -- filter for surface type
        if filterSurface == false or state.surface == surfaceId then
            for type, typeSites in pairs(types) do
                -- filter for resource type
                if filterResources == false or state.resources[type] ~= nil then
                    for key, site in pairs(typeSites) do
                        -- filter for only tracking
                        local insert = true
                        if state.onlyTracked == true and site.tracking == false then
                            insert = false
                        elseif state.onlyEmpty == true and site.amount > 0 then
                            insert = false
                        elseif (site.amount / site.initial_amount) * 100 > (state.maxPercent or 100) then
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

    return sites
end

function UiMenu.onShow(event)
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.onSelectedTabChanged(event)
    local state = Ui.State.get(event.player_index)
    state.menu.tab = event.element.selected_tab_index or nil
end

function UiMenu.onSiteShow(site, player)
    local preview = UiMenu.getPreview(player)
    if preview ~= nil then
        preview.clear()
        Ui.Window.createInner(preview, 'previewsite' .. site.id, site.name)
    end
    Ui.Site.show(site, player, preview[Ui.Window.ROOT_FRAME .. 'previewsite' .. site.id])
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
        state.surface = event.element.selected_index or nil
    else
        state.surface = nil
    end

    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onToggleOnlyTracked(event, player, state)
    state.onlyTracked = event.element.state or false
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onToggleOnlyEmpty(event, player, state)
    state.onlyEmpty = event.element.state or false
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetMaxPercent(event, player, state)
    state.maxPercent = tonumber(event.element.text)
    if state.maxPercent > 100 then state.maxPercent = 100 end
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state UiStateMenuFilter
function UiMenu.filters.onSetSearch(event, player, state)
    state.search = event.element.text
    if state.search == '' then state.search = nil end
    UiMenu.show(player)
end

function UiMenu.surfaces.onScan(event)
    Scanner.scan_surface(game.surfaces[event.element.tags.surfaceId])
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.surfaces.onAutoTrack(event)
    local types = Sites.storage.getSurfaceList()[event.element.tags.surfaceId]
    local surface = game.surfaces[event.element.tags.surfaceId]
    for _, inner in pairs(types or {}) do
        for __, site in pairs(inner) do
            if site.tracking == false then
                local miners = surface.count_entities_filtered {
                    area = {left_top = {x = site.area.left, y = site.area.top}, right_bottom = {x = site.area.right, y = site.area.bottom}},
                    type = 'mining-drill',
                }
                if miners > 0 then
                    site.tracking = true
                end
                game.players[event.player_index].print('Now tracking ' .. site.name)
            end
        end
    end
end

function UiMenu.surfaces.onReset(event)
    Scanner.cache.resetSurface(event.element.tags.surfaceId)
    local sites = Sites.storage.getSurfaceList()[event.element.tags.surfaceId] or {}
    for _, inner in pairs(sites) do
        for __, site in pairs(inner) do
            Sites.storage.remove(site)
        end
    end
    UiMenu.show(game.players[event.player_index])
end

local function surface_tracking_helper(surfaceId, tracking)
    for _, sites in pairs(Sites.storage.getSurfaceList()[surfaceId] or {}) do
        for __, site in pairs(sites) do
            site.tracking = tracking
        end
    end
end

function UiMenu.surfaces.onTrackAll(event)
    surface_tracking_helper(event.element.tags.surfaceId, true)
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.surfaces.onUntrackAll(event)
    surface_tracking_helper(event.element.tags.surfaceId, false)
    UiMenu.show(game.players[event.player_index])
end

---@param state UiStateDashboard
function UiMenu.dashboard.onToggleValue(event, state)
    state[event.element.tags.state_key] = event.element.state
    UiMenu.show(game.players[event.player_index])
end

return UiMenu
