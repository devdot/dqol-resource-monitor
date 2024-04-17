_DEBUG = true
_VERSION = {
    major = 0,
    minor = 0,
    patch = 3,
    string = '0.0.3',
}

-- second screen mod ideas
--    ore field timer (rework that one mod for it?!)
--    live production stats
--    overview/dashboard for logistics network / ltn?
--    train stats (current used etc)
--    send screenshots to secondary screen

require('commands/commands')

require('util/util')

require('components/sites')
require('components/scanner')
require('components/ui/ui')


---Called on mod startup
function boot(event)
    Scanner.boot()
    Sites.boot()
    Ui.boot()
end

---Called on new players
function boot_player(player)
    Ui.init(player)    
end

---This is called when this mod is new to a save, before migrations
function on_init(event)
    boot(event)
end

---This is called when this mod is not new to a save, after migrations
function on_load(event)
    boot(event)
end

---This is called after on_init/on_load when the mod config changed
---@see https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html
function on_configuration_changed()
    game.print('config changed')
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
    boot_player(game.players[event.player_index])
end

script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)

-- function export_stats(event)
--   for k, force in pairs(game.forces) do
--     for item, amount in pairs(force.item_production_statistics.input_counts) do
--       write_output("item_production." .. item .. " " .. amount)
--     end
--     for item, amount in pairs(force.item_production_statistics.output_counts) do
--       write_output("item_consumption." .. item .. " " .. amount)
--     end
--     for item, amount in pairs(force.fluid_production_statistics.input_counts) do
--       write_output("fluid_production." .. item .. " " .. amount)
--     end
--     for item, amount in pairs(force.fluid_production_statistics.output_counts) do
--       write_output("fluid_consumption." .. item .. " " .. amount)
--     end
--   end
-- end

-- function write_output(line)
--   game.write_file('stats.' .. game.tick, line .. "\n", true)
-- end
