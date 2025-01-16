for _, player in pairs(game.players) do
    -- reset the state
    Ui.State.reset(player.index)

    -- re-boot dashboard
    Ui.Dashboard.bootPlayer(player)

    -- re-create the button
    Ui.Menu.createButton(player)
end

-- initialize pinned
for _, site in pairs(Sites.storage.getIdList()) do
    site.pinned = false
end
