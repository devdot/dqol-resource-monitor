Settings = {}

---@param setting string
---@param player_index integer?
function Settings.update(setting, player_index)
    if setting == 'dqol-resource-monitor-site-map-markers' then Settings.updateMapTags(player_index)
    elseif setting == 'dqol-resource-monitor-site-map-markers-untracked' then Settings.updateMapTags(player_index)
    elseif setting == 'dqol-resource-monitor-site-map-markers-threshold' then Settings.updateMapTags(player_index)
    elseif setting == 'dqol-resource-monitor-site-name-generator' then Settings.updateCustomPattern(player_index)
    elseif setting == 'dqol-resource-monitor-site-name-generator-custom-pattern' then Settings.updateCustomPattern(player_index)
    end
end

function Settings.updateAll()
    Settings.updateMapTags()
end

---@param player_index integer?
function Settings.updateMapTags(player_index)
    if player_index then
        game.players[player_index].print('Updated Map Tag Settings')
    end

    for _, site in pairs(Sites.storage.getIdList()) do
        Sites.site.updateMapTag(site)
    end
end


---@param player_index integer?
function Settings.updateCustomPattern(player_index)
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

function Settings.boot()
    script.on_event({ defines.events.on_runtime_mod_setting_changed }, function(e)
        Settings.update(e.setting, e.player_index or nil)
    end)
end

function Settings.on_configuration_changed(event)
    -- check if we changed or just some other mods
    if event.mod_changes['dqol-resource-monitor'] == nil then
        return
    end

    Settings.updateAll()
end

