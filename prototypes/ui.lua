local style = data.raw['gui-style']['default']

style.dqol_resource_monitor_table_row_button = {
    type = 'button_style',
    horizontally_stretchable = 'on',
    bottom_margin = -3,
    padding = 0,
    default_font_color = {250/255,250/255,250/255},
    hovered_font_color = { 0.0, 0.0, 0.0 },
    selected_clicked_font_color = { 0.97, 0.54, 0.15 },
    selected_font_color = { 0.97, 0.54, 0.15 },
    selected_hovered_font_color = { 0.97, 0.54, 0.15 },
    clicked_graphical_set = {
        corner_size = 8,
        position = { 352, 17 }
        -- position = { 51, 17 }
    },
    default_graphical_set = {
        corner_size = 8,
        position = { 208, 17 }
    },
    hovered_graphical_set = {
        base = {
            corner_size = 8,
            position = { 34, 17 }
        },
    },
}

style.dqol_resource_monitor_table_row_flow = {
    type = 'horizontal_flow_style',
}

style.dqol_resource_monitor_table_row_subheading = {
    type = 'horizontal_flow_style',
    parent = 'dqol_resource_monitor_table_row_flow',
    padding = 4,
}

style.dqol_resource_monitor_table_cell = {
    type = 'label_style',
    margin = 0,
    width = 40,
    horizontal_align = 'left',
    padding = 0,
}

style.dqol_resource_monitor_table_cell_resource = {
    type = 'label_style',
    parent = 'dqol_resource_monitor_table_cell',
    horizontal_align = 'center',
    width = 24,
}

style.dqol_resource_monitor_table_cell_padding = {
    type = 'label_style',
    parent = 'dqol_resource_monitor_table_cell',
    width = 10,
}

style.dqol_resource_monitor_table_cell_name = {
    type = 'label_style',
    parent = 'dqol_resource_monitor_table_cell',
    width = 250,
}

style.dqol_resource_monitor_table_cell_number = {
    type = 'label_style',
    parent = 'dqol_resource_monitor_table_cell',
    horizontal_align = 'right',
    width = 60,
}

