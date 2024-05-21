if _DEBUG == true then
    commands.add_command('dqol-resource-monitor-exec', 'debug tool', require('exec'))
    commands.add_command('dqol-resource-monitor-scan', 'debug tool', require('scan'))
    commands.add_command('dqol-resource-monitor-reset-sites', 'debug tool', require('reset-sites'))
end

commands.add_command('dqol-resource-monitor-remove-resource-labels-mod', 'Remove the labels from Resource Labels Updated', require('remove-resource-labels-mod'))
