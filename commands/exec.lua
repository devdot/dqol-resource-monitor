return function(command)
  if _G[command.parameter] ~= nil then
    game.print('execute ' .. command.parameter)
    game.print('> ' .. serpent.block(_G[command.parameter]()))
  else
    game.print('function ' .. command.parameter .. ' not found!')
  end
end
