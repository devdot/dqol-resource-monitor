---@alias UiStateMenuFilter {resources: table<string, true>, surface: integer?, onlyTracked: boolean, onlyArchived: boolean, onlyPinned: boolean, maxPercent: integer, maxEstimatedDepletion: integer?, minAmount: integer, search: string?, orderBy: nil|'resource'|'name'|'amount'|'percent'|'rate'|'depletion', orderByDesc: boolean?}
---@alias UiStateMenu {tab: integer?, refresh: boolean?, open_site_id: integer?, open_surface_id: integer?, sites_filters: UiStateMenuFilter, dashboard_filters: UiStateMenuFilter, use_products: boolean}

---@alias UiStateDashboard {mode: 'always'|'hover'|'never', show_headers: boolean, prepend_surface: 'name'|'icon'|'none', transparent_background: boolean, is_hovering: boolean, columns: string[]}

---@alias UiStatePlayer {menu: UiStateMenu, dashboard: UiStateDashboard}
---@alias GlobalUi {players: table<integer, UiStatePlayer>?}

---Generate a new player state
---@return UiStatePlayer
function generate_fresh_player_state()
    return {
        menu = {
            tab = nil,
            refresh = false,
            open_site_id = nil,
            open_surface_id = nil,
            use_products = table_size(Resources.cleanResources()) > table_size(Resources.cleanProducts()),
            sites_filters = {
                resources = {},
                surface = nil,
                onlyTracked = true,
                onlyArchived = false,
                onlyPinned = false,
                maxPercent = 100,
                maxEstimatedDepletion = nil,
                minAmount = 0,
                search = nil,
                orderBy = nil,
                orderByDesc = false,
            },
            dashboard_filters = {
                resources = {},
                surface = nil,
                onlyTracked = true,
                onlyArchived = false,
                onlyPinned = false,
                maxPercent = 100,
                maxEstimatedDepletion = 4 * 60 * 60 * 60, -- four hours
                minAmount = 0,
                search = nil,
                orderBy = 'percent',
                orderByDesc = false,
            }
        },
        dashboard = {
            mode = 'always',
            show_headers = true,
            prepend_surface = 'none',
            is_hovering = false,
            transparent_background = false,
            columns = {'type', 'name', 'amount', 'percent', 'depletion'},
        },
    }
end

return require(_DQOL_CORE_PATH .. 'scripts/ui/state'):new(generate_fresh_player_state)
