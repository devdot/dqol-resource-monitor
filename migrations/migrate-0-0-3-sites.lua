game.print('Run migration 0.0.3 sites')
-- migrate site structures

local sites = Sites.get_sites_from_cache_all()

if global.sites == nil then global.sites = {} end
if global.sites.ids == nil then global.sites.ids = {} end

local nextId = #(global.sites.ids) or 1
for i, surfaces in pairs(sites) do
    for j, types in pairs(surfaces) do
        for k, site in pairs(types) do
            -- add an id if it does not have one
            if site.id == nil then
                site.id = nextId
                global.sites.ids[nextId] = site
                nextId = nextId + 1
            end

            -- add area if it does not exist
            if site.area == nil then
                local key, pos = pairs(site.positions)(site.positions)
                site.area = {top = pos.y, bottom = pos.y, left = pos.x, right = pos.x}
                Sites.update_site_area(site)
            end
            
            -- add tracking if it is not set
            if site.tracking == nil then
                site.tracking = true
            end

            -- todo: marker?
        end
    end
end

