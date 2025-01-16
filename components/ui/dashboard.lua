local UiDashboard = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-sites',
    UPDATE_INTERVAL = 60,
}

---@param player LuaPlayer
---@return LuaGuiElement
local function create_dashboard(player)
    local state = Ui.State.get(player.index)

    local isFrame = state.dashboard.transparent_background == false
    local root = Ui.mod_gui.get_frame_flow(player).add {
        type = (isFrame and 'frame') or 'flow',
        name = UiDashboard.ROOT_FRAME,
        style = (isFrame and 'dqol_resource_monitor_dashboard_frame') or 'dqol_resource_monitor_dashboard_noframe',
        direction = 'vertical',
    }

    if state.dashboard.show_headers then
        local header = root.add { type = 'flow', name = 'header', style = 'dqol_resource_monitor_table_row_flow' }
        header.add { type = 'label', caption = '[img=utility/resource_editor_icon]', tooltip = {'dqol-resource-monitor.ui-site-type'}, style = 'dqol_resource_monitor_table_cell_resource' }
        header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-name]', tooltip = {'dqol-resource-monitor.ui-site-name'}, style = 'dqol_resource_monitor_table_cell_name_sm' }
        header.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-amount]', tooltip = {'dqol-resource-monitor.ui-site-amount'}, style = 'dqol_resource_monitor_table_cell_number_sm' }
        header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-depletion]', tooltip = {'dqol-resource-monitor.ui-site-rate'}, style = 'dqol_resource_monitor_table_cell_number_sm' }
        header.add { type = 'label', caption = '[img=dqol-resource-monitor-filter-percent]', tooltip = {'dqol-resource-monitor.ui-site-percent'}, style = 'dqol_resource_monitor_table_cell_number' } 
    
        root.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    end
    

    local sites = root.add { type = 'flow', name = 'sites', direction = 'vertical' }
    sites.style.vertical_spacing = 0

    return root
end

---@param player LuaPlayer
---@return LuaGuiElement
local function get_dashboard(player)
    return Ui.mod_gui.get_frame_flow(player)[UiDashboard.ROOT_FRAME] or create_dashboard(player)
end

---@param player LuaPlayer
local function remove_dashboard(player)
    local old = Ui.mod_gui.get_frame_flow(player)[UiDashboard.ROOT_FRAME]
    if old ~= nil then old.destroy() end
end

---Called on mod load/init
function UiDashboard.boot()
    script.on_nth_tick(UiDashboard.UPDATE_INTERVAL, UiDashboard.onUpdate)
end

---@param player LuaPlayer
function UiDashboard.bootPlayer(player)
    UiDashboard.update(player)
end


---Update dashboard with new UI
---@param player LuaPlayer
function UiDashboard.update(player)
    remove_dashboard(player)
    UiDashboard.fill(player)
end

---Fill sites into dashboard UI for a given player
---@param player LuaPlayer
function UiDashboard.fill(player)
    local state = Ui.State.get(player.index)
    local show = state.dashboard.mode == 'always' or state.dashboard.is_hovering

    if show ~= true then
        remove_dashboard(player)
        return
    end
    
    local sites = Ui.Menu.filters.getSites(state.menu.dashboard_filters, state.menu.use_products)
    if #sites == 0 then
        -- hide when empty
        remove_dashboard(player)
        return
    end

    local root = get_dashboard(player)
    local table = root.sites
    table.clear()

    local name_mode = state.dashboard.prepend_surface or 'none'

    for siteKey, site in pairs(sites) do
        local row = table.add { type = 'flow',  style = 'dqol_resource_monitor_table_row_flow' }

        local tags = {
            _module = 'site',
            _action = 'show',
            site_id = site.id,
        }
        local color = Util.Integer.toColor(site.calculated.percent)
        
        local name = site.name
        if name_mode == 'name' then
            name = { '', Surfaces.surface.getNameById(site.surface), ' ', name }
        elseif name_mode == 'icon' then
            name = { '', Surfaces.surface.getIconString(site.surface), ' ', name }
        end

        row.add { type = 'label', caption = Resources.getIconString(site.type), tags = tags, style = 'dqol_resource_monitor_table_cell_resource' }
        local nameLabel = row.add { type = 'label', caption = name, tooltip = name, tags = tags, style = 'dqol_resource_monitor_table_cell_name_sm' }
        row.add { type = 'label', style = 'dqol_resource_monitor_table_cell_padding' }
        local amountLabel = row.add { type = 'label', caption = Util.Integer.toExponentString(site.calculated.amount), tags = tags, style = 'dqol_resource_monitor_table_cell_number_sm' }
        local percentLabel = row.add { type = 'label', caption = Util.Integer.toPercent(site.calculated.percent), tags = tags, style = 'dqol_resource_monitor_table_cell_number_sm' }
        local depletionLabel = row.add { type = 'label', caption = Util.Integer.toTimeString(site.calculated.estimated_depletion, 'never'), tags = tags, style = 'dqol_resource_monitor_table_cell_number' }
        nameLabel.style.font_color = color
        amountLabel.style.font_color = color
        percentLabel.style.font_color = color
        depletionLabel.style.font_color = color
    end

end

function UiDashboard.onUpdate(event)
    for key, player in pairs(game.players) do
        UiDashboard.fill(player)
    end
end

return UiDashboard
