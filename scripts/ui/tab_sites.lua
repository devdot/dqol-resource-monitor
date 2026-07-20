Ui.Menu.tabs.sites = {}

function Ui.Menu.tabs.sites.create(tab)
    Ui.Filters.create(tab, 'sites_filters')

    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    main.style.vertically_stretchable = true

    -- left side
    local sites_outer = main.add { name = 'sites_outer', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    sites_outer.style.width = 500
    sites_outer.style.natural_height = 600
    sites_outer.style.margin = 8
    sites_outer.style.vertically_stretchable = true
    local sites_header = sites_outer.add { type = 'flow', style = 'dqol_resource_monitor_table_row_flow' }
    sites_header.style.height = 28
    sites_header.style.width = 480
    sites_header.style.left_margin = 8
    sites_header.style.top_margin = 4
    sites_header.add { type = 'label', caption = '[img=utility/resource_editor_icon]', tooltip = {'dqol-resource-monitor.ui-site-type'}, style = 'dqol_resource_monitor_table_cell_resource' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-name]', tooltip = {'dqol-resource-monitor.ui-site-name'}, style = 'dqol_resource_monitor_table_cell_name' }
    sites_header.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-amount]', tooltip = {'dqol-resource-monitor.ui-site-amount'}, style = 'dqol_resource_monitor_table_cell_number' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-rate]', tooltip = {'dqol-resource-monitor.ui-site-rate'}, style = 'dqol_resource_monitor_table_cell_number' }
    sites_header.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
    sites_header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-percent]', tooltip = {'dqol-resource-monitor.ui-site-percent'}, } 
    local sites = sites_outer.add { name = 'sites', type = 'scroll-pane' }
    sites.vertical_scroll_policy = 'always'
    sites.style.horizontally_stretchable = true
    sites.style.vertically_stretchable = true

    -- right side
    local site_outer = main.add {
        name = 'site_outer',
        type = 'frame',
        style = 'deep_frame_in_shallow_frame',
        direction = 'vertical',
    }
    site_outer.style.natural_width = 400
    site_outer.style.natural_height = 600
    site_outer.style.margin = 8
    site_outer.style.left_margin = 0
    site_outer.style.padding = 4
    site_outer.style.vertically_stretchable = true
    local site_title = site_outer.add { name = 'title', type = 'flow', direction = 'horizontal' }
    site_title.style.height = 26
    site_title.style.width = 392
    site_title.style.horizontally_stretchable = true
    site_title.style.vertical_align = 'center'
    local site_rename = site_outer.add { name = 'rename', type = 'flow', direction = 'horizontal', visible = false }
    site_rename.style.height = 26
    site_rename.style.width = 392
    site_rename.style.horizontally_stretchable = true
    site_rename.style.vertical_align = 'center'
    local site_inner = site_outer.add {name = 'site', type = 'flow', direction = 'vertical'}
    local site_details = site_outer.add { type = 'scroll-pane', name = 'details' }
    site_details.style.horizontally_stretchable = true
    site_details.style.vertically_stretchable = true
    site_details.vertical_scroll_policy = 'always'
    site_details.style.padding = 4
    site_details.style.left_margin = -4
    site_details.style.right_margin = -4
end

function Ui.Menu.tabs.sites.fill(tab)
    -- add filter with state
    local state = Ui.State:get(tab.player_index).menu.sites_filters
    Ui.Filters.fill(tab, state, 'sites_filters')

    local sites = tab.main.sites_outer.sites
    sites.clear()

    -- fill sites
    local filteredSites = Ui.Filters.getSites(state, Ui.State:get(tab.player_index).menu.use_products)
    local lastSurface = 0

    local showSurfaceSubheading = state.orderBy == nil and state.surface == nil and #game.surfaces > 1
    local appendSurfaceName = state.orderBy ~= nil and state.surface == nil and #game.surfaces > 1
    for key, site in pairs(filteredSites) do
        -- check if we should print the surface name
        if showSurfaceSubheading and lastSurface ~= site.surface then
            -- surface label row
            local row = sites.add { type = 'flow', style = 'dqol_resource_monitor_table_row_subheading' }

            lastSurface = site.surface
            -- row.add { type = 'label', caption = Surfaces.surface.getIconString(site.surface), style = 'dqol_resource_monitor_table_cell_resource'}
            row.add {
                type = 'label',
                style = 'caption_label',
                caption = Surfaces.surface.getNameById(site.surface)
            }
        end

        -- site row
        local row_button = sites.add {
            type = 'button',
            style = 'dqol_resource_monitor_table_row_button',
            tags = {
                _module = 'site',
                _action = 'show',
                site_id = site.id,
            },
        }

        local row = row_button.add { type = 'flow', style = 'dqol_resource_monitor_table_row_flow', ignored_by_interaction = true }
        local name = site.name
        if appendSurfaceName then
            name = { '', Surfaces.surface.getNameById(site.surface), ' ', name }
        end
        row.add { type = 'label', caption = Resources.getIconString(site.type), style = 'dqol_resource_monitor_table_cell_resource' }
        row.add { type = 'label', caption = name, style = 'dqol_resource_monitor_table_cell_name' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        row.add { type = 'label', caption = Util.Integer.toExponentString(site.calculated.amount, 2), style = 'dqol_resource_monitor_table_cell_number' }
        local rateString = (site.calculated.rate and Util.Integer.toExponentString(site.calculated.rate) .. '/s') or '-'
        row.add { type = 'label', caption = rateString, style = 'dqol_resource_monitor_table_cell_number' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local percentLabel = row.add { type = 'label', caption = Util.Integer.toPercent(site.calculated.percent) }
        percentLabel.style.font_color = Util.Integer.toColor(site.calculated.percent)
    end

    if #filteredSites == 0 then
        sites.add {
            type = 'label',
            caption = { 'dqol-resource-monitor.ui-menu-sites-empty' }
        }
    end

    -- fill site if set
    local state = Ui.State:get(tab.player_index)
    if state.menu.open_site_id then
        Ui.Site.showInMenu(state.menu.open_site_id, tab.main.site_outer)
    end
end
