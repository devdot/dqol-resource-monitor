local Window = {
    ROOT_FRAME = Ui.ROOT_FRAME .. '-window'
}

---@alias WindowGui LuaGuiElement

---Create a new window
---@param player LuaPlayer
---@param id string?
---@param title string?
---@return WindowGui
function Window.create(player, id, title)
    Window.close(player, id)

    local window = player.gui.screen.add {
        type = 'frame',
        name = Window.ROOT_FRAME .. (id or ''),
        direction = 'vertical',
        tags = {
            dqol_resource_monitor_window = true,
        },
    }

    window = Window.fillTitlebar(window, title)
    window = Window.fillInner(window)

    window.force_auto_center()
    -- window.bring_to_front()
    -- window.focus()
    player.opened = window

    return window
end

---Create an inner window
---@param parent LuaGuiElement
---@param id string?
---@param title string?
---@return WindowGui
function Window.createInner(parent, id, title)
    local window = parent.add {
        name = Window.ROOT_FRAME .. (id or ''),
        type = 'flow',
        direction = 'vertical',
        tags = {
            dqol_resource_monitor_window = true,
        },
    }
    window = Window.fillInnerTitlebar(window, title)
    window = Window.fillInner(window)
    return window
end

---Fill any GUI Element with a titlebar
---@param gui LuaGuiElement
---@param title string?
---@return LuaGuiElement
function Window.fillTitlebar(gui, title)
    local titlebar = gui.add { type = 'flow', name = 'titlebar' }
    titlebar.drag_target = gui
    titlebar.add { type = 'label', name = 'title', style = 'frame_title', caption = title or 'Title', ignored_by_interaction = true }
    local filler = titlebar.add { type = 'empty-widget', style = 'draggable_space', ignored_by_interaction = true }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    titlebar.add {
        name = 'close',
        type = 'sprite-button',
        style = 'cancel_close_button',
        sprite = 'utility/close',
        tags = {
            _module = 'window',
            _action = 'close',
        }
     }
    return gui
end

---Fill any GUI Element with a titlebar, this is meant to be used with sub-windows
---@param gui LuaGuiElement
---@param title string?
---@return LuaGuiElement
function Window.fillInnerTitlebar(gui, title)
    local titlebar = gui.add { type = 'flow', name = 'titlebar' }
    titlebar.add { type = 'label', name = 'title', style = 'heading_2_label', caption = title or 'Title' }
    return gui
end

---Fill any GUI Element with the inner parts of a window
---@param gui LuaGuiElement
---@return LuaGuiElement
function Window.fillInner(gui)
    gui.add { type = 'flow', name = 'inner', direction = 'vertical' }
    return gui
end

---Close the current window (if open)
---@param player LuaPlayer
---@param id string?
function Window.close(player, id)
    if player.gui.screen[Window.ROOT_FRAME .. (id or '')] ~= nil then
        player.gui.screen[Window.ROOT_FRAME .. (id or '')].destroy()
    end
end

---Get the current window, if exists
---@param player LuaPlayer
---@param id string?
---@return WindowGui?
function Window.get(player, id)
    local window = player.gui.screen[Window.ROOT_FRAME .. (id or '')]
    if window ~= nil and window.tags.dqol_resource_monitor_window then
        return window
    else
        return nil
    end
end

---@param window WindowGui
function Window.refreshTitle(window, title)
    window.titlebar.title.caption = title
end

---@param window WindowGui
function Window.clearInner(window)
    if window.inner then window.inner.destroy() end
    Window.fillInner(window)
end

local function get_id_from_gui_element(element)
    local id = string.sub(element.name or '', string.len(Window.ROOT_FRAME) + 1)
    if id == '' then return nil else return id end
end

---Try to find the window that is associated with this even
---@param event any
---@return WindowGui?
function Window.getWindowFromEvent(event)
    local element = event.element
    while element ~= nil and element.tags.dqol_resource_monitor_window ~= true do
        element = element.parent
    end

    return element
end

---Try to find the window id that is associated with this event
---@param event any
---@return string?
function Window.getWindowIdFromEvent(event)
    return get_id_from_gui_element(Window.getWindowFromEvent(event))
end

function Window.onClose(event)
    
    Window.close(game.players[event.player_index], Window.getWindowIdFromEvent(event))
end

return Window
