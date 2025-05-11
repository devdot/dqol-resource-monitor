return function()
    game.print('Re-Scanning Bitumen Seeps')
    for surface_id, types in pairs(Sites.storage.getSurfaceList()) do
        local surface = game.surfaces[surface_id]
        for type, sites in pairs(types) do
            if type == 'bitumen-seep' then
                for _, site in pairs(sites) do
                    Sites.updater.updateSite(site)
                    
                    if site.calculated.amount == 0 then
                        game.print('Found empty bitumen seep: ' .. site.name)
                        Scanner.py_update_bitumen_seep(site.area, surface)
                        Sites.storage.remove(site)
                    end
                end
            end
        end
    end
end
