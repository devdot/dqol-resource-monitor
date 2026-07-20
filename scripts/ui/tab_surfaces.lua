Ui.Menu.tabs.surfaces = {}

function Ui.Menu.tabs.surfaces.create(tab)
    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    main.style.horizontally_stretchable = true
    main.style.vertically_stretchable = true

    -- left side
    local surfaces_outer = main.add { name = 'surfaces_outer', type = 'frame', style = 'deep_frame_in_shallow_frame' }
    surfaces_outer.style.width = 500
    surfaces_outer.style.natural_height = 600
    surfaces_outer.style.margin = 8
    local surfaces = surfaces_outer.add { type = 'scroll-pane', name = 'surfaces' }
    surfaces.vertical_scroll_policy = 'always'
    surfaces.style.horizontally_stretchable = true
    surfaces.style.vertically_stretchable = true

    -- right side
    local surface_outer = main.add { name = 'surface_outer', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    surface_outer.style.minimal_width = 400
    surface_outer.style.natural_height = 600
    surface_outer.style.margin = 8
    surface_outer.style.left_margin = 0
    surface_outer.style.padding = 4
    surface_outer.style.vertically_stretchable = true
    local surface_title = surface_outer.add { type = 'flow', direction = 'horizontal', name = 'title' }
    surface_title.style.vertical_align = 'center'
    surface_title.add { type = 'sprite', name = 'icon', stretch_image_to_widget_size = true }.style.width = 32
    surface_title.add { type = 'label', name = 'title', style = 'heading_2_label', caption = '' }
    surface_title.style.bottom_margin = 4
    surface_outer.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }.style.bottom_margin = 4
    local surface = surface_outer.add { type = 'scroll-pane', name = 'surface' }
    surface.style.horizontally_stretchable = true
    surface.style.vertically_stretchable = true
    -- surface.vertical_scroll_policy = 'always'
end

function Ui.Menu.tabs.surfaces.fill(tab)
    local surfaces = tab.main.surfaces_outer.surfaces
    surfaces.clear()
    for index, surface in pairs(Surfaces.getVisibleSurfaces()) do
        local row_button = surfaces.add {
            type = 'button',
            style = 'dqol_resource_monitor_table_row_button',
            tags = {
                _module = 'surface',
                _action = 'show',
                surface_id = surface.id,
            },
        }
        
        local row = row_button.add{ type = 'flow', style = 'dqol_resource_monitor_table_row_flow', ignored_by_interaction = true }
        
        -- add resources
        local resources_string = ''
        for _, resource in pairs(surface.resources) do
            resources_string = resources_string .. Resources.getIconString(resource)
        end

        row.add { type = 'label', caption = Surfaces.surface.getName(surface), style = 'dqol_resource_monitor_table_cell_name' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local resources_label = row.add { type = 'label', caption = resources_string, style = 'dqol_resource_monitor_table_cell' }
        resources_label.style.width = 200
    end

    -- fill surface if set
    local state = Ui.State:get(tab.player_index)
    if state.menu.open_surface_id then
        Ui.Surface.showInMenu(state.menu.open_surface_id, tab.main.surface_outer)
    end
end
