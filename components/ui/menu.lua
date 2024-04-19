local UiMenu = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-menu',
    BUTTON_NAME = Ui.ROOT_FRAME .. '-menu-show',
    WINDOW_ID = 'menu',
    tabs = {},
}

---@param LuaPlayer
function UiMenu.bootPlayer(player)
    UiMenu.createButton(player)
end

---@param player LuaPlayer
function UiMenu.createButton(player)
    local flow = Ui.mod_gui.get_button_flow(player)
    if flow[UiMenu.BUTTON_NAME] ~= nil then
        flow[UiMenu.BUTTON_NAME].destroy()
    end

    flow.add {
        type = 'sprite-button',
        name = UiMenu.BUTTON_NAME,
        tooltip = { 'dqol-resource-monitor.ui-menu-button-tooltip' },
        sprite = 'item/rocket-control-unit',
        style = Ui.mod_gui.button_style,
        tags = {
            _module = 'menu',
            _action = 'show',
        }
    }
end

---Display the main window
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiMenu.show(player, window)
    if window == nil then
        window = Ui.Window.create(player, UiMenu.WINDOW_ID, { 'dqol-resource-monitor.ui-menu-title' })
    end

    if window.inner ~= nil then window.inner.destroy() end
    local inner = window.add { name = 'inner', type = 'frame', style = 'inside_deep_frame' }
    local tabs = inner.add { name = 'tabbed', type = 'tabbed-pane' }
    
    -- add all tabs here
    for name, func in pairs(UiMenu.tabs) do
        local caption = tabs.add { type = 'tab', caption = { 'dqol-resource-monitor.ui-menu-tab-' .. name } }
        local tab = tabs.add { name = name, type = 'flow', direction = 'vertical' }
        func(tab)
        tabs.add_tab(caption, tab)
    end
end

function UiMenu.tabs.sites(tab)
    local filters = tab.add {
        name = 'filters',
        type = 'table',
        style = 'compact_slot_table',
        column_count = table_size(Resources.types),
    }
    filters.style.margin = 8

    for key, resource in pairs(Resources.types) do
        filters.add {
            type = 'sprite-button',
            style = 'compact_slot_sized_button',
            toggled = false,
            sprite = resource.type .. '/' .. resource.name,
            tooltip = { resource.type .. '-name.' .. resource.name },
            -- todo: add actions and make them filter
        }
    end

    local main = tab.add { name = 'main', type = 'flow', direction = 'horizontal' }
    local sites_frame = main.add { name = 'sites', type = 'frame', style = 'deep_frame_in_shallow_frame' }
    sites_frame.style.natural_width = 300
    sites_frame.style.natural_height = 600
    sites_frame.style.margin = 8
    -- sites_frame.style.right_margin = 10
    local sites = sites_frame.add { name = 'sites', type = 'table', column_count = 4 }
    local preview = main.add { name = 'preview', type = 'frame', style = 'deep_frame_in_shallow_frame', direction = 'vertical' }
    preview.style.natural_width = 400
    preview.style.natural_height = 600
    preview.style.margin = 8
    preview.style.left_margin = 0
    preview.style.padding = 4

    -- fill sites
    -- todo: actual filtering
    local filteredSites = Sites.get_sites_by_id()
    for key, site in pairs(filteredSites) do
        local type = Resources.types[site.type]
        sites.add { type = 'label', caption = '[' .. type.type .. '=' .. type.name .. ']' }
        sites.add { type = 'label', caption = site.name }
        sites.add { type = 'label', caption = Util.Integer.toExponentString(site.amount) }
        sites.add {
            type = 'sprite-button',
            style = 'mini_button',
            sprite = 'utility/rename_icon_small_black',
            tags = {
                _module = 'menu_site',
                _action = 'show',
                site_id = site.id,
            },
        }
    end
    if #filteredSites == 0 then
        sites_frame.add {
            type = 'label',
            caption = {'dqol-resource-monitor.ui-menu-sites-empty'}
        }
    end
end

function UiMenu.tabs.other(tab)
    tab.add { type = 'label', caption = 'other' }

    local buttons = tab.add { name = 'buttons', type = 'frame', style = 'slot_button_deep_frame', direction = 'horizontal' }
    buttons.style.margin = 8
    buttons.add {
        type = 'button',
        style = 'slot_button',
        caption = 'test',
    }
end

---@param player LuaPlayer
---@return LuaGuiElement?
function UiMenu.getPreview(player)
    local window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    if window == nil then
        UiMenu.show(player)
        window = Ui.Window.get(player, UiMenu.WINDOW_ID)
    end

    if window == nil then return nil end
    if window['inner'] == nil or window['inner']['tabbed'] == nil then return nil end -- todo change this
    return window['inner']['tabbed']['sites']['main']['preview'] or nil
end

function UiMenu.onShow(event)
    UiMenu.show(game.players[event.player_index])
end

function UiMenu.onSiteShow(site, player)
    local preview = UiMenu.getPreview(player)
    if preview ~= nil then
        preview.clear()
        Ui.Window.createInner(preview, 'previewsite' .. site.id, site.name)
    end
    Ui.Site.show(site, player, preview[Ui.Window.ROOT_FRAME .. 'previewsite' .. site.id])
end

return UiMenu
