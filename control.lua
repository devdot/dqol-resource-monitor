require('version')

if _DEBUG then require('commands/commands') end

require('util/util')

require('components/translation')
require('components/settings')
require('components/resources')
require('components/sites')
require('components/surfaces')
require('components/scanner')
require('components/ui/ui')

-- enable gvv
if script.active_mods['gvv'] then
    require('__gvv__.gvv')()
end

---Called on mod startup
function boot(event)
    Resources.boot()
    Settings.boot()
    Scanner.boot()
    Sites.boot()
    Ui.boot()
end

---Called on new players
function boot_player(player)
    Ui.bootPlayer(player)
    Resources.bootPlayer(player)
end

function reboot_players()
    for key, player in pairs(game.players) do boot_player(player) end    
end

---This is called when this mod is new to a save, before migrations
function on_init(event)
    boot(event)

    Scanner.onInitMod()
    Sites.onInitMod()
    Surfaces.onInitMod()

    reboot_players()
end

---This is called when this mod is not new to a save, after migrations
function on_load(event)
    boot(event)
end

---This is called after on_init/on_load when the mod config changed
---@see https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
function on_configuration_changed(event)
    Resources.on_configuration_changed()
    Settings.on_configuration_changed(event)
    Surfaces.on_configuration_changed()
    Ui.on_configuration_changed(event)
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)


---This is called when a player is created (singleplayer game start)
function on_player_created(event)
    boot_player(game.players[event.player_index])
end

---This is called when a player is created in multiplayer (join)
function on_player_joined_game(event)
    -- this is also called in singleplayer once when the game is created
    -- therefore, filter when tick is 0
    if game.tick > 0 then
        boot_player(game.players[event.player_index])
    end
end

script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
