-- update dashboard state to defaults
for _, player in pairs(game.players) do
    local state = Ui.State.get(player.index)
    state.dashboard.columns = {'type', 'name', 'amount', 'percent', 'depletion'}
end