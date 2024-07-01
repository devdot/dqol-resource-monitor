UiState = {}

---@alias UiStateMenuFilter {resources: table<string, true>, surface: integer?, onlyTracked: boolean, onlyEmpty: boolean, maxPercent: integer, search: string?}
---@alias UiStateMenu {tab: integer?, sites_filters: UiStateMenuFilter, dashboard_filters: UiStateMenuFilter}

---@alias UiStateDashboard {show_headers: boolean, prepend_surface_name: boolean}

---@alias UiStatePlayer {menu: UiStateMenu, dashboard: UiStateDashboard}
---@alias GlobalUi {players: table<integer, UiStatePlayer>?}
---@cast global {ui: GlobalUi?}

---@param LuaPlayer
function UiState.bootPlayer(player)
    UiState.reset(player.index)
end

---Reset the entire UI State for a player (or all if none provided)
---@param player_index integer?
function UiState.reset(player_index)
    if global.ui == nil or global.ui.players == nil then
        global.ui = {
            players = {},
        }
    end

    if player_index ~= nil then
        global.ui.players[player_index] = UiState.generateFreshPlayerState()
    else
        for key, state in pairs(global.ui.players) do
            global.ui.players[key] = UiState.generateFreshPlayerState()
        end
    end
end

---Get the UI State for a single player. Will create a state if this player is not known.
---@param player_index integer
---@return UiStatePlayer
function UiState.get(player_index)
    if global.ui == nil or global.ui.players == nil then
        UiState.reset(player_index)
    end

    if global.ui.players[player_index] == nil then
        UiState.reset(player_index)
    end

    return global.ui.players[player_index]
end

---Generate a new player state
---@return UiStatePlayer
function UiState.generateFreshPlayerState()
    return {
        menu = {
            tab = nil,
            sites_filters = {
                resources = {},
                surface = nil,
                onlyTracked = true,
                onlyEmpty = false,
                maxPercent = 100,
                search = nil,
            },
            dashboard_filters = {
                resources = {},
                surface = nil,
                onlyTracked = true,
                onlyEmpty = false,
                maxPercent = 100,
                search = nil,
            }
        },
        dashboard = {
            show_headers = false,
            prepend_surface_name = false,
        },
    }
end

return UiState
