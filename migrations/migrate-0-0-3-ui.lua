game.print('Run migration 0.0.3 ui')
-- migrate ui frame

for key, player in pairs(game.players) do
    local old = Ui.mod_gui.get_frame_flow(player)[Ui.ROOT_FRAME]
    if old ~= nil then old.destroy() end
end
