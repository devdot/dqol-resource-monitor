_DEBUG = true
_VERSION = {
    major = 0,
    minor = 0,
    patch = 2,
    string = '0.0.2',
}

-- second screen mod ideas
--    ore field timer (rework that one mod for it?!)
--    live production stats
--    overview/dashboard for logistics network / ltn?
--    train stats (current used etc)
--    send screenshots to secondary screen

require('commands/commands')

require('components/sites')
require('components/scanner')
require('components/ui')



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
