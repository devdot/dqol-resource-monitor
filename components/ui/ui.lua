Ui = {
    mod_gui = require("mod-gui"),
    ROOT_FRAME = 'dqol-resource-monitor-ui',
    BUTTON_ROUTER = {}
}

Ui.Window = require('components/ui/window')
Ui.Menu = require('components/ui/menu')
Ui.Site = require('components/ui/site')
Ui.Surface = require('components/ui/surface')
Ui.Dashboard = require('components/ui/dashboard')
Ui.State = require('components/ui/state')

Ui.routes = {
    window = {
        close = Ui.Window.onClose,
    },
    site = {
        show = Ui.Menu.onSiteShow,
        highlight = Ui.Site.onHighlight,
        rename_open = Ui.Site.onRenameOpen,
        rename = Ui.Site.onRename,
        update = Ui.Site.onUpdate,
        delete_open = Ui.Site.onDeleteOpen,
        delete = Ui.Site.onDelete,
        toggle_tracking = Ui.Site.onToggleTracking,
        toggle_pin = Ui.Site.onTogglePin,
        merge_open = Ui.Site.onMergeOpen,
        merge_confirm = Ui.Site.onMergeConfirm,
    },
    surface = {
        show = Ui.Menu.onSurfaceShow,
        
        scan = Ui.Surface.onScan,
        auto_track = Ui.Surface.onAutoTrack,
        reset = Ui.Surface.onReset,
        track_all = Ui.Surface.onTrackAll,
        untrack_all = Ui.Surface.onUntrackAll,
        add_map_tags = Ui.Surface.onAddMapTags,
        remove_map_tags = Ui.Surface.onRemoveMapTags,
    },
    menu = {
        show = Ui.Menu.onShow,
        toggle = Ui.Menu.onToggle,
        tab_select = Ui.Menu.onSelectedTabChanged,
        use_products_toggle = Ui.Menu.onUseProductsToggle,
        toggle_resource_type_setting = Ui.Menu.onToggleResourceTypeSetting,
    },
    menu_filters = {
        toggle_resource = Ui.Menu.filters.onToggleResource,
        select_surface = Ui.Menu.filters.onSelectSurface,
        toggle_filter = Ui.Menu.filters.onToggleFilter,
        set_max_percent = Ui.Menu.filters.onSetMaxPercent,
        set_max_estimated_depletion = Ui.Menu.filters.onSetMaxEstimatedDepletion,
        set_min_amount = Ui.Menu.filters.onSetMinAmount,
        set_search = Ui.Menu.filters.onSetSearch,
        set_order_by = Ui.Menu.filters.onSetOrderBy,
    },
    menu_dashboard = {
        toggle_setting = Ui.Menu.dashboard.onToggleSetting,
        select_setting = Ui.Menu.dashboard.onSelectSetting,
    },
}

-- uses a LuaGuiElement's tags to route
-- route definition (element tags)
--      _module: the routing module
--      _action: the routing action
--      _only: only route when the event matches the one here (from defines.events)
-- routes definition (Ui.routes)
--      modules are the keys
--      within the modules there are keys that represent actions and their values are the callbacks
--      __prepare is called to prepare the arguments that are given to actions
local function route_event(event)
    if event.element then
        -- check if there is a filter present
        -- filter out if it does not match
        if event.element.tags._only and event.element.tags._only ~= event.name then return end

        -- use gui element tags to route this event
        local module = event.element.tags._module
        if module ~= nil then
            local action = event.element.tags._action
            if Ui.routes[module] then
                -- call the prepare method (and if it does not exist, simply put {event} into args)
                local args = (Ui.routes[module].__prepare or function(e) return { e } end)(event)
                -- call the action method
                Ui.routes[module][action](table.unpack(args))
            end
        end
    end
end

Ui.routes.site.__prepare = function(event)
    return {
        Sites.storage.getById(event.element.tags.site_id or 0),
        game.players[event.player_index],
        event,
    }
end

Ui.onClick = route_event
Ui.onConfirmed = route_event
Ui.onSelectionChanged = route_event
Ui.onCheckedChanged = route_event
Ui.onValueChanged = route_event
Ui.onSelectedTabChanged = route_event
Ui.onSwitchStateChanged = route_event
Ui.onHoverIn = route_event
Ui.onHoverOut = route_event

function Ui.routes.surface.__prepare(event)
    return {
        Surfaces.storage.getById(event.element.tags.surface_id),
        game.players[event.player_index],
        event,
    }
end

function Ui.routes.menu_filters.__prepare(event)
    return {
        event,
        game.players[event.player_index],
        Ui.State.get(event.player_index).menu[event.element.tags.filter_group or 'sites_filters'],
    }
end

function Ui.routes.menu_dashboard.__prepare(event)
    return {
        event,
        Ui.State.get(event.player_index).dashboard,
    }    
end

function Ui.onClosed(event)
    if event.element then
        if event.element.tags.dqol_resource_monitor_window then
            Ui.Window.onClose(event)
        end
    end
end

---This is supposed to be called after load/init
function Ui.boot()
    script.on_event({ defines.events.on_gui_click }, Ui.onClick)
    script.on_event({ defines.events.on_gui_confirmed }, Ui.onConfirmed)
    script.on_event({ defines.events.on_gui_selection_state_changed }, Ui.onSelectionChanged)
    script.on_event({ defines.events.on_gui_checked_state_changed }, Ui.onCheckedChanged)
    script.on_event({ defines.events.on_gui_value_changed }, Ui.onValueChanged)
    script.on_event({ defines.events.on_gui_selected_tab_changed }, Ui.onSelectedTabChanged)
    script.on_event({ defines.events.on_gui_switch_state_changed }, Ui.onSwitchStateChanged)
    script.on_event({ defines.events.on_gui_closed }, Ui.onClosed)
    script.on_event({ defines.events.on_gui_hover }, Ui.onHoverIn)
    script.on_event({ defines.events.on_gui_leave }, Ui.onHoverOut)

    -- subcomponents
    Ui.Dashboard.boot()
end

---This is supposed to run on on_player_created or (or multiplayer join?)
---@param player LuaPlayer
function Ui.bootPlayer(player)
    Ui.State.bootPlayer(player)
    Ui.Menu.bootPlayer(player)
    Ui.Dashboard.bootPlayer(player)
end

function Ui.on_configuration_changed(event)
    -- check if we changed or just some other mods
    if event.mod_changes['dqol-resource-monitor'] == nil then
        return
    end

    for _, player in pairs(game.players) do
        Ui.Menu.close(player)
    end
end
