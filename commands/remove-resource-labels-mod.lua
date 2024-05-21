return function()
    if script.active_mods['resourceMarker'] then
        game.print('please run command: resourcemarker delete')
    else
        game.print('Mod Resource Labels Updated is not installed, cannot remove their labels!')
    end
end
