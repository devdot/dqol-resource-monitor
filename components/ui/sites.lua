local UiSites = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-sites',
    UPDATE_INTERVAL = 60,
}

local function create_root(player)
    return Ui.mod_gui.get_frame_flow(player).add {
        type = 'frame',
        name = UiSites.ROOT_FRAME,
    }
end

local function get_root(player)
    return Ui.mod_gui.get_frame_flow(player)[UiSites.ROOT_FRAME] or create_root(player)
end

local function remove_root(player)
    local old = Ui.mod_gui.get_frame_flow(player)[UiSites.ROOT_FRAME]
    if old ~= nil then old.destroy() end
end

local function get_new_root(player)
    remove_root(player)
    return create_root(player)
end

---Called on mod load/init
function UiSites.boot()
    script.on_nth_tick(UiSites.UPDATE_INTERVAL, UiSites.onUpdate)
end

---Update Sites UI for a given player
---@param player LuaPlayer
function UiSites.update(player)
    local root = get_new_root(player)

    local gui = root.add {
        type = 'table',
        name = 'sites',
        style = 'statistics_element_table',
        column_count = 5,
        draw_horizontal_line_after_headers = true,
    }

    gui.add { type = 'label', style = 'caption_label', caption = '' }
    gui.add { type = 'label', style = 'caption_label', caption = {'dqol-resource-monitor.ui-site-name'} }
    gui.add { type = 'label', style = 'caption_label', caption = {'dqol-resource-monitor.ui-site-amount'} }
    gui.add { type = 'label', style = 'caption_label', caption = {'dqol-resource-monitor.ui-site-initial-amount'} }
    gui.add { type = 'label', style = 'caption_label', caption = '' }

    for surface_index, types in pairs(Sites.get_sites_from_cache_all()) do
        for type, sites in pairs(types) do
            for siteKey, site in pairs(sites) do
                gui.add { type = 'label', caption = '[item=' .. site.type .. ']' }
                gui.add { type = 'label', caption = site.name }
                gui.add { type = 'label', caption = Util.Integer.toExponentString(site.amount) }
                gui.add { type = 'label', caption = Util.Integer.toExponentString(site.initial_amount) }

                local buttons = gui.add { type = 'flow', direction = 'horizontal' }
                buttons.add {
                    type = 'sprite-button',
                    style = 'mini_button',
                    sprite = 'utility/rename_icon_small_black',
                    name = 'show',
                    tags = {
                        _module = 'site',
                        _action = 'show',
                        site_id = site.id,
                    }
                }
            end
        end
    end
end

function UiSites.onUpdate(event)
    for key, player in pairs(game.players) do
        UiSites.update(player)
    end
end

return UiSites
