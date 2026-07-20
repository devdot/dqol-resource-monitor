Ui.Menu.tabs.dashboard = {}

function Ui.Menu.tabs.dashboard.create(tab)
    Ui.Filters.create(tab, 'dashboard_filters')

    tab.add { name = 'main', type = 'flow', direction = 'vertical'}
end

function Ui.Menu.tabs.dashboard.fill(tab)
    -- immediately update dashboard
    Ui.Dashboard.update(game.players[tab.player_index])

    -- add filter with state
    local state = Ui.State:get(tab.player_index)
    Ui.Filters.fill(tab, state.menu.dashboard_filters, 'dashboard_filters')

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
            caption = { localized },
            tooltip = { localized .. '-tooltip' },
            tags = {
                _module = 'dashboard',
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
            table.insert(items, { localized .. '-option-' .. item })
            reversed[item] = #items
        end

        settings.add { type = 'label', caption = { localized }, tooltip = { localized .. '-tooltip' } }
        settings.add {
            type = 'drop-down',
            name = setting,
            tooltip = { localized .. '-tooltip' },
            items = items,
            selected_index = reversed[state.dashboard[setting]] or nil,
            tags = {
                _module = 'dashboard',
                _action = 'select_setting',
                _only = defines.events.on_gui_selection_state_changed,
                index = options,
                setting = setting,
            },
        }
    end

    -- add custom column setting
    settings.add {
        type = 'label',
        caption = { 'dqol-resource-monitor.ui-menu-dashboard-columns' },
        tooltip = { 'dqol-resource-monitor.ui-menu-dashboard-columns-tooltip' },
    }
    settings.add {
        type = 'textfield',
        tooltip = { 'dqol-resource-monitor.ui-menu-dashboard-columns-tooltip' },
        text = table.concat(state.dashboard.columns or {}, ','),
        lose_focus_on_confirm = true,
        tags = {
            _module = 'dashboard',
            _action = 'update_columns',
            _only = defines.events.on_gui_confirmed,
        }
    }.style.width = 400
end

---@type { __prepare: UiPrepareFunction, [string]: fun(state: UiStateDashboard, player: LuaPlayer, tags: Tags, event: UiBasicEvent) }
Ui.Core.routes.dashboard = {
    __prepare = function(event)
        return {
            Ui.State:get(event.player_index).dashboard,
            game.players[event.player_index],
            event.element.tags,
            event,
        }
    end,

    toggle_setting = function(state, player, tags, event)
        state[tags.setting] = event.element.state
        Ui.Menu.open(player)
    end,

    select_setting = function(state, player, tags, event)
        state[tags.setting] = tags.index[event.element.selected_index]
        Ui.Menu.open(player)
    end,

    update_columns = function(state, player, tags, event)
        local text = event.element.text or ''
        state.columns = {}
        for column in string.gmatch(text, "[a-z]+") do
            -- make sure this is one of the allowed columns
            if Ui.Dashboard.columns[column] ~= nil then
                table.insert(state.columns, column)
            end
        end

        Ui.Menu.open(player)
    end,
}
