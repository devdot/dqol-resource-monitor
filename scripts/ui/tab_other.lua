Ui.Menu.tabs.other = {}

function Ui.Menu.tabs.other.create(tab)
end

---@param tab LuaGuiElement
function Ui.Menu.tabs.other.fill(tab)
    tab.clear()

    tab.add { name = 'top_flow', type = 'flow', direction = 'horizontal' }

    local info = tab.top_flow.add { type = 'table', column_count = 2 }
    info.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-other-info-headline'}, style = 'caption_label' }
    info.add { type = 'label', caption = '' }
    
    if storage.sites and storage.sites.updater then
        local queueLength = #storage.sites.updater.queue
        local chunksPerUpdate = settings.global['dqol-resource-monitor-site-chunks-per-update'].value
        local ticksBetweenUpdates = settings.global['dqol-resource-monitor-site-ticks-between-updates'].value
        local ticksToFinishQueue = ticksBetweenUpdates * (queueLength + 1)
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-length' } }
        info.add { type = 'label', caption = queueLength }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-position' } }
        info.add { type = 'label', caption = storage.sites.updater.pointer }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-total-chunks' } }
        info.add { type = 'label', caption = ((queueLength - 1) * chunksPerUpdate) + (#(storage.sites.updater.queue[#storage.sites.updater.queue] or {})) }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-chunks-per-update' } }
        info.add { type = 'label', caption = chunksPerUpdate }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-ticks-between-updates' } }
        info.add { type = 'label', caption = ticksBetweenUpdates }
        info.add { type = 'label', caption = { 'dqol-resource-monitor.ui-menu-other-updater-queue-duration' } }
        info.add { type = 'label', caption = Util.Integer.toTimeString(ticksToFinishQueue) .. ' (' .. ticksToFinishQueue .. ')' }
    else
        info.add { type = 'label', caption = 'Updater is not initialized yet. If the mod was just loaded, you may need to wait a little. Otherwise, check that there are sites with tracking enabled.' }
        info.add { type = 'label', caption = '' }
    end

    tab.top_flow.add { type = 'line' }
    
    local addSite = tab.top_flow.add { name = 'add_site', type = 'flow', direction = 'vertical' }
    addSite.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-other-sites-add'}, style = 'caption_label'}
    local addSiteForm = addSite.add { name = 'form', type = 'flow', direction = 'horizontal' }

    local surfaces = {}
    local indexToSurface = {}
    for _, surface in pairs(Surfaces.getVisibleSurfaces()) do
        table.insert(surfaces, Surfaces.surface.getName(surface))
        table.insert(indexToSurface, surface.id)
    end
    addSiteForm.add {
        name = 'surface',
        type = 'drop-down',
        items = surfaces,
        selected_index = 1,
        tooltip = {'dqol-resource-monitor.ui-site-surface'},
        tags = {
            indexToSurface = indexToSurface,
        },
    }
    local resources = {}
    local indexToResource = {}
    for type, resource in pairs(Resources.types) do
        table.insert(resources, resource.translated_name)
        table.insert(indexToResource, type)
    end
    addSiteForm.add {
        name = 'resource',
        type = 'drop-down',
        items = resources,
        selected_index = 1,
        tooltip = {'dqol-resource-monitor.ui-site-type'},
        tags = {
            indexToResource = indexToResource,
        },
    }
    addSiteForm.add {
        type = 'button',
        caption = { 'dqol-resource-monitor.ui-ok' },
        tooltip = {'dqol-resource-monitor.ui-menu-other-sites-add'},
        style = 'item_and_count_select_confirm',
        tags = {
            _module = 'site',
            _action = 'add',
        }
    }

    tab.add { type = 'line' }
    tab.add {
        type = 'switch',
        switch_state = (Ui.State:get(tab.player_index).menu.use_products and 'right') or 'left',
        allow_none_state = false,
        right_label_caption = {'dqol-resource-monitor.ui-menu-other-use-products-switch-products'},
        right_label_tooltip = {'dqol-resource-monitor.ui-menu-other-use-products-switch-products-tooltip'},
        left_label_caption = {'dqol-resource-monitor.ui-menu-other-use-products-switch-resources'},
        left_label_tooltip = {'dqol-resource-monitor.ui-menu-other-use-products-switch-resources-tooltip'},
        tags = {
            _module = 'other',
            _action = 'use_products_toggle',
        }
    }
    
    tab.add { type = 'line' }
    tab.add { type = 'label', caption = {'dqol-resource-monitor.ui-menu-other-types-label'}, style = 'info_label' }
    local scroll = tab.add { type = 'scroll-pane' }
    local table = scroll.add { type = 'table', column_count = 7 }
    table.add { type = 'label', caption = 'resource name' }
    table.add { type = 'label', caption = 'category' }
    table.add { type = 'label', caption = 'infinite' }
    table.add { type = 'label', caption = 'hidden' }
    table.add { type = 'label', caption = 'ignore tracking' }
    table.add { type = 'label', caption = 'loose merge' }
    table.add { type = 'label', caption = 'products' }

    local toggles = {'infinite', 'hidden', 'tracking_ignore', 'loose_merge'}

    for _, type in pairs(Resources.types) do
        table.add { type = 'label', caption = type.resource_name }
        table.add { type = 'label', caption = type.category }.style.horizontally_squashable = true
        
        for _, toggle in pairs(toggles) do
            table.add {
                type = 'checkbox',
                state = type[toggle],
                tags = {
                    _module = 'other',
                    _action = 'toggle_resource_type_setting',
                    resource_name = type.resource_name,
                    setting = toggle,
                }
            }
        end

        local products = ''
        for __, product in pairs(Resources.getProducts(type.resource_name)) do
            products = products .. ' ' .. product.name
        end
        table.add { type = 'label', caption = products }.style.horizontally_squashable = true
    end
end

---@type {[string]: fun(event: UiBasicEvent)}
Ui.Core.routes.other = {
    use_products_toggle = function(event)
        local player = game.players[event.player_index]
        local toggle = event.element.switch_state == 'right'
        Ui.State:get(event.player_index).menu.use_products = toggle

        -- recreate menu
        Ui.Menu.close(player)
        Ui.Menu.open(player)
    end,

    toggle_resource_type_setting = function(event)
        local tags = event.element.tags
        local player = game.players[event.player_index]
        
        -- change that setting
        local type = Resources.types[tags.resource_name] or nil
        if type == nil or type[tags.setting] == nil then return end
        type[tags.setting] = event.element.state or false

        -- recreate menu
        Ui.Menu.close(player)
        Ui.Menu.open(player)
    end,
}
