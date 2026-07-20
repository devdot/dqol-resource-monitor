-- make sure there is no stuck UI
if game.tick > 0 then
    for index, player in pairs(game.players) do
        local old_window = player.gui.screen['dqol-resource-monitor-ui-windowmenu']
        if old_window then
            log('Remove opened old menu for player ' .. index)
            old_window.destroy()
        end

        local old_button = Ui.mod_gui.get_button_flow(player)['dqol-resource-monitor-ui-menu-show']
        if old_button then
            old_button.name = Ui.Menu.BUTTON_NAME
            log('Rename old menu button for player ' .. index)
        end
    end
end
