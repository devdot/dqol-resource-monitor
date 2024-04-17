data:extend({
    {
        name = 'external-dashboard-site-ticks-between-updates',
        type = 'int-setting',
        default_value = 600,
        minimum_value = 1,
        maximum_value = 216000,
        setting_type = 'runtime-global',
        order = 'site01',
    },
    {
        name = 'external-dashboard-site-entities-per-update',
        type = 'int-setting',
        default_value = 0,
        minimum_value = 0,
        maximum_value = 1000000,
        setting_type = 'runtime-global',
        order = 'site02',
    },
    {
        name = 'external-dashboard-site-map-markers',
        type = 'bool-setting',
        default_value = true,
        setting_type = 'runtime-global',
        order = 'site03',
    },
    {
        name = 'external-dashboard-site-auto-scan',
        type = 'bool-setting',
        default_value = true,
        setting_type = 'runtime-global',
        order = 'site04',
    },
    {
        name = 'external-dashboard-ui-button-show',
        type = 'bool-setting',
        default_value = true,
        setting_type = 'runtime-global',
        order = 'ui01',
    },
    {
        name = 'external-dashboard-ui-sites-show',
        type = 'bool-setting',
        default_value = true,
        setting_type = 'runtime-global',
        order = 'ui02',
    },

    -- per player
})
