local UiMenu = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-menu',
    BUTTON_NAME = Ui.ROOT_FRAME .. '-menu-show',
    WINDOW_ID = 'menu',
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
    }
end

---Display the main window
---@param player LuaPlayer
---@param window LuaGuiElement?
function UiMenu.show(player, window)
    if window == nil then
        window = Ui.Window.create(player, UiMenu.WINDOW_ID, { 'dqol-resource-monitor.ui-menu-title' })
    end

    local buttons = window.add {name = 'buttons', type = 'flow', direction = 'horizontal'}
    buttons.add { type = 'label', caption = 'buttons' } -- todo remove

    local filters = window.add {name = 'filters', type = 'flow', direction = 'horizontal'}
    buttons.add { type = 'label', caption = 'filters' } -- todo remove

    local main = window.add {name = 'main', type = 'flow', direction = 'horizontal'}
    local sites = main.add {name = 'sites', type = 'table', column_count = 4}
    local preview = main.add { name = 'preview', type = 'flow', direction = 'vertical' }
    
    -- fill sites
    -- todo: actual filtering
    local filteredSites = Sites.get_sites_by_id()
    for key, site in pairs(filteredSites) do
        sites.add { type = 'label', caption = '[item=' .. site.type .. ']' }
        sites.add { type = 'label', caption = site.name }
        sites.add { type = 'label', caption = Util.Integer.toExponentString(site.amount) }
        sites.add { type = 'sprite-button', style = 'mini_button', sprite = 'utility/rename_icon_small_black', name = UiMenu.ROOT_FRAME .. '-site-show-' .. site.id}
    end
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
    if window['main'] == nil then return nil end
    return window['main']['preview'] or nil
end

function UiMenu.onShow(player, event)
    UiMenu.show(player)
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
