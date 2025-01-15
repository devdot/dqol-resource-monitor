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

style.dqol_resource_monitor_resource_bar = {
    type = 'progressbar_style',
    bar_width = 28,
    horizontally_stretchable = 'on',
    font = 'default-bold',
    vertical_align = 'center',
    embed_text_in_bar = true,
    font_color = {r=230/255, g=227/255, b=230/255},
    filled_font_color = {r=0/255, g=0/255, b=0/255},
    bar_background = table.deepcopy(style['progressbar'].bar_background),
}

-- sprites
local filter_names = {'default', 'resource', 'name', 'amount', 'percent', 'rate', 'depletion'}
local filter_sprites = {}
for _, direction in pairs({ 'asc', 'desc' }) do
    for __, name in pairs(filter_names) do
        table.insert(filter_sprites, {
            type = 'sprite',
            name = 'dqol-resource-monitor-filter-' .. name .. '-' .. direction,
            filename = '__dqol-resource-monitor__/graphics/filter-' .. name .. '-' .. direction .. '.png',
            priority = 'extra-high',
            width = 64,
            height = 64,
            flags = { 'gui-icon' }
        })
    end
end
filter_names[1] = nil
filter_names[2] = nil
for _, name in pairs(filter_names) do
    table.insert(filter_sprites, {
        type = 'sprite',
        name = 'dqol-resource-monitor-filter-' .. name,
        filename = '__dqol-resource-monitor__/graphics/filter-' .. name .. '.png',
        priority = 'extra-high',
        width = 64,
        height = 64,
        flags = { 'gui-icon' }
    })
end

data:extend {
    {
        type = 'sprite',
        name = 'dqol-resource-monitor-logo',
        filename = '__dqol-resource-monitor__/graphics/logo.png',
        priority = 'extra-high',
        width = 128,
        height = 128,
        flags = {'gui-icon'}
    },
    {
        type = 'sprite',
        name = 'dqol-resource-monitor-remove-map-tag',
        filename = '__dqol-resource-monitor__/graphics/remove-map-tag.png',
        priority = 'extra-high',
        width = 37,
        height = 49,
        flags = {'gui-icon'}
    },
    {
        type = 'sprite',
        name = 'dqol-resource-monitor-site-merge',
        filename = '__dqol-resource-monitor__/graphics/site-merge.png',
        priority = 'extra-high',
        width = 64,
        height = 64,
        flags = {'gui-icon'}
    },
    {
        type = 'sprite',
        name = 'dqol-resource-monitor-site-track',
        filename = '__dqol-resource-monitor__/graphics/site-track.png',
        priority = 'extra-high',
        width = 64,
        height = 64,
        flags = {'gui-icon'}
    },
    table.unpack(filter_sprites)
}
