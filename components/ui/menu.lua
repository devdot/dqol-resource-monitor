local UiMenu = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-menu',
    BUTTON_NAME = Ui.ROOT_FRAME .. '-menu-show',
    WINDOW_ID = 'menu',
    tabs = {},
    filters = {},
    surfaces = {},
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

    if window.inner ~= nil then window.inner.destroy() end
    local inner = window.add { name = 'inner', type = 'frame', style = 'inside_deep_frame' }
    local tabs = inner.add { name = 'tabbed', type = 'tabbed-pane' }
    
    -- add all tabs here
    for name, func in pairs(UiMenu.tabs) do
        local caption = tabs.add { type = 'tab', caption = { 'dqol-resource-monitor.ui-menu-tab-' .. name } }
        local tab = tabs.add { name = name, type = 'flow', direction = 'vertical' }
        func(tab)
        tabs.add_tab(caption, tab)
    end
end

function UiMenu.tabs.sites(tab)
    local filterGroup = tab.add { type = 'flow', direction = 'vertical', }
    filterGroup.style.margin = 8
    local state = UiMenu.filters.getState()

    local showResourceFilterReset = table_size(state.resources) > 0
    local resourceFilter = filterGroup.add {
        name = 'filters',
        type = 'table',
        style = 'compact_slot_table',
        column_count = table_size(Resources.types) + ((showResourceFilterReset and 1) or 0),
    }

    for key, resource in pairs(Resources.types) do
        resourceFilter.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            toggled = state.resources[resource.resource_name] ~= nil,
            sprite = resource.type .. '/' .. resource.name,
            tooltip = { 'dqol-resource-monitor.ui-menu-filter-resource-tooltip', { resource.type .. '-name.' .. resource.name }},
            tags = {
                _module = 'menu_filters',
                _action = 'toggle_resource',
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
                reset = true,
            },
        }
        reset.style.size = 36
    end

    -- generate surfaces
    local surfaces = {}
    for index, surface in pairs(game.surfaces) do surfaces[surface.index] = surface.name end

    local surfaceFilter = filterGroup.add { type = 'flow', direction = 'horizontal', }
    local surfaceSelect = surfaceFilter.add {
        name = 'surface',
        type = 'drop-down',
        items = surfaces,
        selected_index = state.surface or 0,
        tooltip = {'dqol-resource-monitor.ui-menu-filter-surface-tooltip'},
        tags = {
            _module = 'menu_filters',
            _action = 'select_surface',
            _only = defines.events.on_gui_selection_state_changed,
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
                reset = true,
            },
        }
    end

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
        }
    }

    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    local sites_frame = main.add { name = 'sites', type = 'frame', style = 'deep_frame_in_shallow_frame' }
    sites_frame.style.natural_width = 300
    sites_frame.style.natural_height = 600
    sites_frame.style.margin = 8
    -- sites_frame.style.right_margin = 10
    local sites = sites_frame.add { name = 'sites', type = 'table', column_count = 5 }
    local preview = main.add { name = 'preview', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    preview.style.natural_width = 400
    preview.style.natural_height = 600
    preview.style.margin = 8
    preview.style.left_margin = 0
    preview.style.padding = 4

    -- fill sites
    local filteredSites = UiMenu.filters.getSites()
    local lastSurface = 0
    for key, site in pairs(filteredSites) do
        -- check if we should print the surface name
        if lastSurface ~= site.surface then
            lastSurface = site.surface
            sites.add { type = 'label' }
            sites.add {
                type = 'label',
                style = 'caption_label',
                caption =  game.surfaces[site.surface].name
            }
            sites.add { type = 'label' }
            sites.add { type = 'label' }
            sites.add { type = 'label' }
        end

        local type = Resources.types[site.type]
        local tags = {
            _module = 'menu_site',
            _action = 'show',
            site_id = site.id,
        }
        sites.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']', tags = tags }
        sites.add { type = 'label', caption = site.name, tags = tags }
        sites.add { type = 'label', caption = Util.Integer.toExponentString(site.amount), tags = tags }
        sites.add { type = 'label', caption = Util.Integer.toPercent(site.amount / site.initial_amount), tags = tags }
        sites.add {
            type = 'sprite-button',
            style = 'mini_button',
            sprite = 'utility/list_view',
            tags = tags,
        }
    end
    if #filteredSites == 0 then
        sites_frame.add {
            type = 'label',
            caption = {'dqol-resource-monitor.ui-menu-sites-empty'}
        }
    end
end

function UiMenu.tabs.surfaces(tab)
    local table = tab.add {
        type = 'table',
        column_count = 3 + table_size(Resources.types),
    }

    -- do the headers
    table.add { type = 'label', style = 'caption_label', caption = { 'dqol-resource-monitor.ui-menu-surfaces-name' } }
    table.add { type = 'label', style = 'caption_label', caption = { 'dqol-resource-monitor.ui-menu-surfaces-chunks' } }
    for _, type in pairs(Resources.types) do
        table.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']' }
    end
    table.add { type = 'label', caption = '' }

    -- gather data
    local scanCache = Scanner.cache.get()
    local allSites = Sites.get_sites_from_cache_all()

    -- fill the surfaces
    for key, surface in pairs(game.surfaces) do
        table.add { type = 'label', caption = surface.name }
        table.add { type = 'label', caption = table_size(scanCache.chunks[surface.index] or {}) }
        
        if allSites[surface.index] ~= nil then
            for _, type in pairs(Resources.types) do
                local sum = 0
                for __, site in pairs(allSites[surface.index][type.resource_name] or {}) do
                    sum = sum + site.amount
                end
                table.add { type = 'label', caption = (sum > 0 and Util.Integer.toExponentString(sum)) or '' }
            end
        else
            for _, type in pairs(Resources.types) do
                table.add { type = 'label', caption = '' }
            end
        end

        local buttons = table.add { type = 'table', style = 'compact_slot_table', column_count = 2 }
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

function UiMenu.tabs.other(tab)
    tab.add { type = 'label', caption = 'other' }

    local buttons = tab.add { name = 'buttons', type = 'frame', style = 'slot_button_deep_frame', direction = 'horizontal' }
    buttons.style.margin = 8
    buttons.add {
        type = 'button',
        style = 'slot_button',
        caption = 'test',
    }
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

---@alias MenuFilterState {resources: table<string, true>, surface: integer?, onlyTracked: boolean, onlyEmpty: boolean}

function UiMenu.filters.resetState()
    if global.ui == nil then global.ui = {} end
    if global.ui.menu == nil then global.ui.menu = {} end
    global.ui.menu.filters = {
        resources = {},
        surface = nil,
        onlyTracked = true,
        onlyEmpty = false,
    }
end

---@return MenuFilterState
function UiMenu.filters.getState()
    if global.ui == nil then
        UiMenu.filters.resetState()
    elseif global.ui.menu == nil then
        UiMenu.filters.resetState()
    elseif global.ui.menu.filters == nil then
        UiMenu.filters.resetState()
    end
    
    return global.ui.menu.filters
end

---@return Site[]
function UiMenu.filters.getSites()
    local state = UiMenu.filters.getState()
    local filterSurface = state.surface ~= nil
    local filterResources = table_size(state.resources) > 0

    ---@type Site[]
    local sites = {}

    for surfaceId, types in pairs(Sites.get_sites_from_cache_all()) do
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

function UiMenu.onSiteShow(site, player)
    local preview = UiMenu.getPreview(player)
    if preview ~= nil then
        preview.clear()
        Ui.Window.createInner(preview, 'previewsite' .. site.id, site.name)
    end
    Ui.Site.show(site, player, preview[Ui.Window.ROOT_FRAME .. 'previewsite' .. site.id])
end

---@param player LuaPlayer
---@param state MenuFilterState
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
---@param state MenuFilterState
function UiMenu.filters.onSelectSurface(event, player, state)
    if event.element.tags.reset == nil then
        state.surface = event.element.selected_index or nil
    else
        state.surface = nil
    end

    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state MenuFilterState
function UiMenu.filters.onToggleOnlyTracked(event, player, state)
    state.onlyTracked = event.element.state or false
    UiMenu.show(player)
end

---@param player LuaPlayer
---@param state MenuFilterState
function UiMenu.filters.onToggleOnlyEmpty(event, player, state)
    state.onlyEmpty = event.element.state or false
    UiMenu.show(player)
end

function UiMenu.surfaces.onScan(event)
    Scanner.scan_surface(game.surfaces[event.element.tags.surfaceId])
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.surfaces.onReset(event)
    Scanner.cache.resetSurface(event.element.tags.surfaceId)
    Sites.get_sites_from_cache_all()[event.element.tags.surfaceId] = nil
    UiMenu.show(game.players[event.player_index])
end

return UiMenu
