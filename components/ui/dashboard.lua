local UiDashboard = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-sites',
    UPDATE_INTERVAL = 60,
}

local function create_root(player)
    return Ui.mod_gui.get_frame_flow(player).add {
        type = 'frame',
        name = UiDashboard.ROOT_FRAME,
    }
end

local function get_root(player)
    return Ui.mod_gui.get_frame_flow(player)[UiDashboard.ROOT_FRAME] or create_root(player)
end

local function remove_root(player)
    local old = Ui.mod_gui.get_frame_flow(player)[UiDashboard.ROOT_FRAME]
    if old ~= nil then old.destroy() end
end

local function get_new_root(player)
    remove_root(player)
    return create_root(player)
end

---Called on mod load/init
function UiDashboard.boot()
    script.on_nth_tick(UiDashboard.UPDATE_INTERVAL, UiDashboard.onUpdate)
end

---Update Sites UI for a given player
---@param player LuaPlayer
function UiDashboard.update(player)
    local state = Ui.State.get(player.index)
    local sites = Ui.Menu.filters.getSites(state.menu.dashboard_filters)

    if #sites == 0 then
        -- hide when empty
        remove_root(player)
        return
    end

    local root = get_new_root(player)

    local gui = root.add {
        type = 'table',
        name = 'sites',
        style = 'statistics_element_table',
        column_count = 5,
        draw_horizontal_line_after_headers = state.dashboard.show_headers or false,
    }
    gui.style.right_cell_padding = 2

    if state.dashboard.show_headers == true then
        gui.add { type = 'label', style = 'caption_label', caption = '' }
        gui.add { type = 'label', style = 'caption_label', caption = {'dqol-resource-monitor.ui-site-name'} }
        gui.add { type = 'label', style = 'caption_label', caption = {'dqol-resource-monitor.ui-site-amount'} }
        gui.add { type = 'label', style = 'caption_label', caption = '' }
        gui.add { type = 'label', style = 'caption_label', caption = '' }
    end

    for siteKey, site in pairs(sites) do
        local type = Resources.types[site.type]
        local tags = {
            _module = 'site',
            _action = 'show',
            site_id = site.id,
        }
        local fraction = site.amount / site.initial_amount
        local color = Util.Integer.toColor(fraction)
        
        local name = site.name
        if state.dashboard.prepend_surface_name == true then
            name = game.surfaces[site.surface].name .. ' ' .. name
        end

        gui.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']', tags = tags }
        local nameLabel = gui.add { type = 'label', caption = name, tags = tags }
        local amountLabel = gui.add { type = 'label', caption = Util.Integer.toExponentString(site.amount), tags = tags }
        local percentLabel = gui.add { type = 'label', caption = Util.Integer.toPercent(fraction), tags = tags }
        nameLabel.style.font_color = color
        amountLabel.style.font_color = color
        percentLabel.style.font_color = color

        local buttons = gui.add { type = 'flow', direction = 'horizontal' }
        buttons.add {
            type = 'sprite-button',
            style = 'mini_button',
            sprite = 'utility/list_view',
            name = 'show',
            tags = tags,
        }
    end

end

function UiDashboard.onUpdate(event)
    for key, player in pairs(game.players) do
        UiDashboard.update(player)
    end
end

return UiDashboard