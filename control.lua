require('version')
_DQOL_CORE_PATH = 'dqol-core/'

-- enable gvv
if script.active_mods['gvv'] then
    require('__gvv__.gvv')()
end

require(_DQOL_CORE_PATH .. 'scripts/control')

require('commands/commands')

require('util/util')

require('components/translation')
require('components/settings')
require('components/resources')
require('components/sites')
require('components/surfaces')
require('components/scanner')
require('components/ui/ui')

Control.start()
