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
        highlight = Ui.Site.onHighlight,
        show = Ui.Site.onShow,
        rename = Ui.Site.onRename,
        update = Ui.Site.onUpdate,
        delete = Ui.Site.onDelete,
        toggle_tracking = Ui.Site.onToggleTracking,
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
        tab_select = Ui.Menu.onSelectedTabChanged,
    },
    menu_site = {   
        show = Ui.Menu.onSiteShow,
    },
    menu_filters = {
        toggle_resource = Ui.Menu.filters.onToggleResource,
        select_surface = Ui.Menu.filters.onSelectSurface,
        toggle_only_tracked = Ui.Menu.filters.onToggleOnlyTracked,
        toggle_only_empty = Ui.Menu.filters.onToggleOnlyEmpty,
        set_max_percent = Ui.Menu.filters.onSetMaxPercent,
        set_search = Ui.Menu.filters.onSetSearch,
    },
    menu_dashbaord = {
        toggle_value = Ui.Menu.dashboard.onToggleValue,
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

local function prepare_site(event)
    return {
        Sites.storage.getById(event.element.tags.site_id or 0),
        game.players[event.player_index],
        event,
    }
end
Ui.routes.site.__prepare = prepare_site
Ui.routes.menu_site.__prepare = prepare_site

Ui.onClick = route_event
Ui.onConfirmed = route_event
Ui.onSelectionChanged = route_event
Ui.onCheckedChanged = route_event
Ui.onValueChanged = route_event
Ui.onSelectedTabChanged = route_event

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

function Ui.routes.menu_dashbaord.__prepare(event)
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
    script.on_event({ defines.events.on_gui_closed }, Ui.onClosed)

    -- subcomponents
    Ui.Dashboard.boot()
end

---This is supposed to run on on_player_created or (or multiplayer join?)
---@param LuaPlayer
function Ui.bootPlayer(player)
    Ui.State.bootPlayer(player)
    Ui.Menu.bootPlayer(player)
end
