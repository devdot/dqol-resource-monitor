local Window = {}

---Create a new window
---@param player LuaPlayer
---@param title string?
---@return LuaGuiElement
function Window.create(player, title)
    Window.close(player)

    local window = player.gui.screen.add {
        type = 'frame',
        name = Ui.ROOT_WINDOW,
        direction = 'vertical',
    }

    local titlebar = window.add { type = 'flow', name = 'titlebar' }
    titlebar.drag_target = window
    titlebar.add { type = 'label', name = 'title', style = 'frame_title', caption = title or 'Title', ignored_by_interaction = true }
    local filler = titlebar.add { type = 'empty-widget', style = 'draggable_space', ignored_by_interaction = true }
    filler.style.height = 24
    filler.style.horizontally_stretchable = true
    titlebar.add { type = 'sprite-button', name = Ui.ROOT_WINDOW .. '-close', style = 'cancel_close_button', sprite = 'utility/close_white' }

    window.force_auto_center()
    -- window.bring_to_front()
    -- window.focus()
    player.opened = window

    return window
end

---Close the current window (if open)
---@param player LuaPlayer
function Window.close(player)
    if player.gui.screen[Ui.ROOT_WINDOW] ~= nil then
        player.gui.screen[Ui.ROOT_WINDOW].destroy()
    end
end

---Get the current window, if exists
---@param player LuaPlayer
---@return LuaGuiElement?
function Window.get(player)
    return player.gui.screen[Ui.ROOT_WINDOW]
end

return Window
