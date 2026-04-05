-- update filters for sites
for _, player in pairs(game.players) do
    local state = Ui.State.get(player.index)
    
    -- remove onlyEmpty
    state.menu.dashboard_filters.onlyEmpty = nil
    state.menu.sites_filters.onlyEmpty = nil

    -- add archived
    state.menu.dashboard_filters.onlyArchived = false
    state.menu.sites_filters.onlyArchived = false
end
