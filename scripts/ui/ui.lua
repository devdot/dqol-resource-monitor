Ui = {
    mod_gui = require("mod-gui"),
    UPDATE_INTERVAL = 60,
}

Ui.Core = require(_DQOL_CORE_PATH .. 'scripts/ui/core')

Ui.Core.events = {
    defines.events.on_gui_click,
    defines.events.on_gui_confirmed,
    defines.events.on_gui_selection_state_changed,
    defines.events.on_gui_checked_state_changed,
    defines.events.on_gui_value_changed,
    defines.events.on_gui_selected_tab_changed,
    defines.events.on_gui_switch_state_changed,
    defines.events.on_gui_closed,
}

---@type UiState<UiStatePlayer>
Ui.State = require('scripts/ui/state')

---@type UiMenu
Ui.Menu = require(_DQOL_CORE_PATH .. 'scripts/ui/menu')
Ui.Menu.getTab = function(player_index) return Ui.State:get(player_index).menu.tab end
Ui.Menu.setTab = function(player_index, tab) Ui.State:get(player_index).menu.tab = tab end
Ui.Menu.BUTTON_HOVER = true
Ui.Menu.NAT_HEIGHT = 880
Ui.Menu.MAX_HEIGHT = 1000
Ui.Menu.NAT_WIDTH = 960
Ui.Menu.MAX_WIDTH = 960
Ui.Menu.REFRESH_INTERVAL = 61 -- odd so it spreads out

Ui.Filters = require('scripts/ui/filters')
Ui.Site = require('scripts/ui/site')
Ui.Surface = require('scripts/ui/surface')
Ui.Dashboard = require('scripts/ui/dashboard')

-- Menu tabs
require('scripts/ui/tab_sites')
require('scripts/ui/tab_surfaces')
require('scripts/ui/tab_dashboard')
require('scripts/ui/tab_other')
if script.active_mods['YARM'] then require('scripts/ui/tab_yarm') end

-- Menu button hover
script.on_event({
    defines.events.on_gui_hover,
    defines.events.on_gui_leave,
},
---@param event EventData.on_gui_hover
function(event)
    if event.element.name == Ui.Menu.BUTTON_NAME then
        local state = Ui.State:get(event.player_index)
        if state.dashboard.mode == 'hover' then
            state.dashboard.is_hovering = event.name == defines.events.on_gui_hover
            Ui.Dashboard.fill(game.players[event.player_index])
        end
    end
end)

-- select tool
script.on_event({
    defines.events.on_player_selected_area,
    defines.events.on_player_reverse_selected_area,
    defines.events.on_player_alt_selected_area,
}, function(event --[[@as EventData.on_player_selected_area]])
    -- validate (this receives events from all select tools)
    if event.item == 'dqol-resource-monitor-area-tool' then
        local state = Ui.State:get(event.player_index)
        Ui.Core.callWithTags({
            _module = 'site',
            _action = 'area_select',
            site_id = state.menu.open_site_id,
        }, event)
    end
end)
