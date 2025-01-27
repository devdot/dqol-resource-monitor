local UiDashboard = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-sites',
    UPDATE_INTERVAL = 60,
    columns = {
        name = {
            img = 'dqol-resource-monitor-filter-name',
            tooltip = { 'dqol-resource-monitor.ui-site-name' },
            style = 'dqol_resource_monitor_table_cell_name_sm',
            value = function (site, state)
                local name_mode = state.prepend_surface or 'none'
                if name_mode == 'name' then
                    return { '', Surfaces.surface.getNameById(site.surface), ' ', site.name }
                elseif name_mode == 'icon' then
                    return { '', Surfaces.surface.getIconString(site.surface), ' ', site.name }
                else
                    return site.name
                end
            end,
        },
        type = {
            img = 'utility/resource_editor_icon',
            tooltip = { 'dqol-resource-monitor.ui-site-type' },
            style = 'dqol_resource_monitor_table_cell_resource',
            value = function (site) return Resources.getIconString(site.type) end
        },
        amount = {
            img = 'dqol-resource-monitor-filter-amount',
            tooltip = { 'dqol-resource-monitor.ui-site-amount' },
            style = 'dqol_resource_monitor_table_cell_number_sm',
            value = function (site) return Util.Integer.toExponentString(site.calculated.amount) end,
        },
        percent = {
            img = 'dqol-resource-monitor-filter-percent',
            tooltip = { 'dqol-resource-monitor.ui-site-percent' },
            style = 'dqol_resource_monitor_table_cell_number_sm',
            value = function (site) return Util.Integer.toPercent(site.calculated.percent) end,
        },
        depletion = {
            img = 'dqol-resource-monitor-filter-depletion',
            tooltip = { 'dqol-resource-monitor.ui-site-estimated-depletion' },
            style = 'dqol_resource_monitor_table_cell_number',
            value = function (site) return Util.Integer.toTimeString(site.calculated.estimated_depletion, {'dqol-resource-monitor.ui-site-estimated-depletion-never'}) end,
        },
        rate = {
            img = 'dqol-resource-monitor-filter-rate',
            tooltip = { 'dqol-resource-monitor.ui-site-rate' },
            style = 'dqol_resource_monitor_table_cell_number_sm',
            value = function (site) return Util.Integer.toExponentString(site.calculated.rate, 2) .. '/s' end,
        },
    },
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
        for _, column in pairs(state.dashboard.columns) do
            local data = UiDashboard.columns[column]
            header.add {
                type = 'label',
                caption = '[img=' .. data.img .. ']',
                tooltip = data.tooltip,
                style = data.style,
            }
        end
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

    for siteKey, site in pairs(sites) do
        local row = table.add { type = 'flow',  style = 'dqol_resource_monitor_table_row_flow' }

        local tags = {
            _module = 'site',
            _action = 'show',
            site_id = site.id,
        }
        local color = Util.Integer.toColor(site.calculated.percent)
        
        for _, column in pairs(state.dashboard.columns) do
            local data = UiDashboard.columns[column]
            row.add {
                type = 'label',
                style = data.style,
                caption = data.value(site, state.dashboard),
                tags = tags,
            }.style.font_color = color
        end
    end

end

function UiDashboard.onUpdate(event)
    for key, player in pairs(game.players) do
        UiDashboard.fill(player)
    end
end

return UiDashboard
