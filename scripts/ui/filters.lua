local UiFilters = {}

---@param state UiStateMenuFilter
---@param use_products? boolean
---@return Site[]
function UiFilters.getSites(state, use_products)
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
                    local products = (Resources.types[type] and Resources.types[type].products) or {}
                    for _, key in pairs(products) do
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
                        elseif state.onlyArchived == true and site.archived ~= true then
                            insert = false
                        elseif state.onlyPinned == true and site.pinned ~= true then
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

---@param tab LuaGuiElement
---@param filter_group 'sites_filters'|'dashboard_filters'
function UiFilters.create(tab, filter_group)
    local filters = tab.add { name = 'filters', type = 'flow', direction = 'vertical' }
    filters.style.margin = 8
    filters.style.vertical_spacing = 2

    local state = Ui.State:get(tab.player_index)

    -- make resource filter
    local useProductsForFilter = state.menu.use_products or false
    local items = (useProductsForFilter and Resources.cleanProducts()) or Resources.cleanResources()
    local resourcesFilter = filters.add {
        name = 'resources',
        type = 'table',
        style = 'compact_slot_table',
        column_count = math.min(24, table_size(items) + 1),
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
                _module = 'filters',
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
            _module = 'filters',
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
                _module = 'filters',
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
            _module = 'filters',
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
                _module = 'filters',
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

    local states = {
        {
            name = 'onlyTracked',
            sprite = 'dqol-resource-monitor-site-track',
            style = 'slot_sized_button_blue',
            localized = 'only-tracked',
        },
        {
            name = 'onlyArchived',
            localized = 'only-archived',
            sprite = 'dqol-resource-monitor-site-archive',
        },
        {
            name = 'onlyPinned',
            localized = 'only-pinned',
            sprite = 'utility/track_button',
        },
    }

    local stateFilter = orderAndStateFilter.add { name = 'states', type = 'table', column_count = #states, style = 'compact_slot_table' }
    for _, item in pairs(states) do
        stateFilter.add {
            type = 'sprite-button',
            name = item.name,
            toggled = false,
            style = item.style or 'compact_slot_sized_button',
            sprite = item.sprite,
            tooltip = {'dqol-resource-monitor.ui-menu-filter-' ..item.localized .. '-tooltip'},
            tags = {
                _module = 'filters',
                _action = 'toggle_filter',
                filter_group = filter_group,
                filter = item.name,
            },
        }.style.size = 36
    end
end

---@param tab LuaGuiElement
---@param state UiStateMenuFilter
---@param filter_group 'sites_filters'|'dashboard_filters'
function UiFilters.fill(tab, state, filter_group)
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
    filters.orderAndState.states.onlyArchived.toggled = state.onlyArchived or false
    filters.orderAndState.states.onlyPinned.toggled = state.onlyPinned or false

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

---@type { __prepare: UiPrepareFunction, [string]: fun(state: UiStateMenuFilter, player: LuaPlayer, tags: Tags, event: UiBasicEvent) }
Ui.Core.routes.filters = {
    __prepare = function(event)
        return {
            Ui.State:get(event.player_index).menu[event.element.tags.filter_group or 'sites_filters'],
            game.players[event.player_index],
            event.element.tags,
            event,
        }
    end,

    toggle_resource = function(state, player, tags)
        if tags.reset == true then
            state.resources = {}
        else
            local resource = tags.resource_name
            if state.resources[resource] == nil then
                state.resources[resource] = true
            else
                state.resources[resource] = nil
            end
        end

        Ui.Menu.open(player)
    end,

    select_surface = function(state, player, tags, event)
        if tags.reset == nil then
            state.surface = (tags.selectToSurfaceId and tags.selectToSurfaceId[event.element.selected_index .. '']) or nil
        else
            state.surface = nil
        end

        Ui.Menu.open(player)
    end,

    toggle_filter = function(state, player, tags)
        local filter = tags.filter
        state[filter] = state[filter] ~= true
        Ui.Menu.open(player)
    end,

    set_max_percent = function(state, player, tags, event)
        state.maxPercent = tonumber(event.element.text) or 100
        if state.maxPercent > 100 then state.maxPercent = 100 end
        Ui.Menu.open(player)
    end,

    set_max_estimated_depletion = function(state, player, tags, event)
        if event.element.text == '' then
            state.maxEstimatedDepletion = nil
        else
            state.maxEstimatedDepletion = tonumber(event.element.text) * 60 * 60 * 60 -- store in ticks
            if state.maxEstimatedDepletion < 0 then state.maxEstimatedDepletion = 0 end
        end
        Ui.Menu.open(player)
    end,

    set_min_amount = function(state, player, tags, event)
        state.minAmount = tonumber(event.element.text) or 0
        state.minAmount = state.minAmount * 1000
        Ui.Menu.open(player)
    end,

    set_search = function(state, player, tags, event)
        state.search = event.element.text
        if state.search == '' then state.search = nil end
        Ui.Menu.open(player)
    end,

    set_order_by = function(state, player, tags)
        state.orderBy = tags.order_by
        state.orderByDesc = tags.order_by_direction == 'desc'
        Ui.Menu.open(player)
    end,
}

return UiFilters
