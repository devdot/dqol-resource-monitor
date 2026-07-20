require('version')
_DQOL_CORE_PATH = 'dqol-core/'

-- enable gvv
if script.active_mods['gvv'] then
    require('__gvv__.gvv')()
end

require(_DQOL_CORE_PATH .. 'scripts/control')

require('commands/commands')

require('util/util')

require('scripts/translation')
require('scripts/settings')
require('scripts/resources')
require('scripts/sites')
require('scripts/surfaces')
require('scripts/scanner')
require('scripts/ui/ui')

Control.start()
