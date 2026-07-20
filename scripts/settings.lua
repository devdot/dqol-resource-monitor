---@param player_index integer?
local function update_map_tags(value, player_index)
    if player_index then
        game.players[player_index].print('Updated Map Tag Settings')
    end

    for _, site in pairs(Sites.storage.getIdList()) do
        Sites.site.updateMapTag(site)
    end
end


---@param player_index integer?
local function update_custom_pattern(value, player_index)
    if settings.global['dqol-resource-monitor-site-name-generator'].value ~= 'Custom' then
        return
    end

    if player_index then
        game.players[player_index].print('Updated Map Custom Site Naming Pattern')
    end

    for _, site in pairs(Sites.storage.getIdList()) do
        site.name = Util.Naming.getCustomName(site.area, site.type, site)
        Sites.site.updateMapTag(site)
    end
end

Control.registerSettingChange(_MOD .. '-site-map-markers', update_map_tags)
Control.registerSettingChange(_MOD .. '-site-map-markers-untracked', update_map_tags)
Control.registerSettingChange(_MOD .. '-site-map-markers-threshold', update_map_tags)
Control.registerSettingChange(_MOD .. '-site-name-generator', update_custom_pattern)
Control.registerSettingChange(_MOD .. '-site-name-generator-custom-pattern', update_custom_pattern)

Control.register('config_changed', function(event)
    -- check if we changed or just some other mods
    if event.mod_changes['dqol-resource-monitor'] == nil then
        return
    end

    update_map_tags()
end)
