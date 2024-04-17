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
                game.players[event.player_index].print('Cannot find site Surface #' .. id)
            end
        elseif command == 'window' then
            local next = iter()
            if next == 'close' then
                Ui.Window.close(game.players[event.player_index])
            end
        end
    end
end

function Ui.onClosed(event)
    if event.element then
        if event.element.name == Ui.Window.ROOT_FRAME then
            Ui.Window.close(game.players[event.player_index])
        end
    end
end

---This is supposed to be called after load/init
function Ui.boot()
    script.on_event({ defines.events.on_gui_click }, Ui.onClick)
    script.on_event({ defines.events.on_gui_closed }, Ui.onClosed)

    -- subcomponents
    Ui.Menu.boot()
    Ui.Sites.boot()
end
