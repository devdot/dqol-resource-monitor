Ui = {
    mod_gui = require("mod-gui"),
    ROOT_FRAME = 'dqol-resource-monitor-ui',
    BUTTON_ROUTER = {}
}

Ui.Window = require('components/ui/window')
Ui.Menu = require('components/ui/menu')
Ui.Site = require('components/ui/site')
Ui.Sites = require('components/ui/sites')

Ui.BUTTON_ROUTER = {
    root = Ui.ROOT_FRAME .. '-',
    rootLength = string.len(Ui.ROOT_FRAME) + 1,
    site = {
        highlight = Ui.Site.onHighlight,
        show = Ui.Site.onShow,
        rename = Ui.Site.onRename,
        update = Ui.Site.onUpdate,
    },
    menu = {
        show = Ui.Menu.onShow,
        site = {
            show = Ui.Menu.onSiteShow,
        },
    }
}

function Ui.onClick(event)
    local name = event.element.name
    if name and string.sub(name, 0, Ui.BUTTON_ROUTER.rootLength) == Ui.BUTTON_ROUTER.root then
        local sub = string.sub(name, Ui.BUTTON_ROUTER.rootLength + 1)

        local iter = string.gmatch('-' .. sub, '-(%w+)')
        local command = iter()

        if command == 'site' then
            local func = iter()
            -- move remaining matches into p
            local id = tonumber(iter()) or 0

            local site = Sites.get_site_by_id(id)

            if site ~= nil then
                Ui.BUTTON_ROUTER.site[func](site, game.players[event.player_index], event)
            else
                game.players[event.player_index].print('Cannot find site #' .. id)
            end
        elseif command == 'window' then
            local next = iter()
            if next == 'close' then
                Ui.Window.onClose(game.players[event.player_index], event)
            end
        elseif command == 'menu' then
            local next = iter()
            if next == 'site' then
                local func = iter()
                local id = tonumber(iter()) or 0
                local site = Sites.get_site_by_id(id)

                if site ~= nil then
                    Ui.BUTTON_ROUTER.menu.site[func](site, game.players[event.player_index], event)
                else
                    game.players[event.player_index].print('Cannot find site #' .. id)
                end
            elseif Ui.BUTTON_ROUTER.menu[next] ~= nil then
                Ui.BUTTON_ROUTER.menu[next](game.players[event.player_index], event)
            end
        end
    end
end

function Ui.onClosed(event)
    if event.element then
        if event.element.tags.dqol_resource_monitor_window then
            Ui.Window.onClose(game.players[event.player_index], event)
        end
    end
end

---This is supposed to be called after load/init
function Ui.boot()
    script.on_event({ defines.events.on_gui_click }, Ui.onClick)
    script.on_event({ defines.events.on_gui_closed }, Ui.onClosed)

    -- subcomponents
    Ui.Sites.boot()
end

---This is supposed to run on on_player_created or (or multiplayer join?)
---@param LuaPlayer
function Ui.bootPlayer(player)
    Ui.Menu.bootPlayer(player)
end
