local mod_gui = require("mod-gui")

Ui = {
    ROOT_FRAME = 'external-dashboard-ui',
    ROOT_WINDOW = 'external-dashboard-ui-window',
}

require('components/ui/window')

local BUTTON_ROUTER = {
    root = Ui.ROOT_FRAME .. '-',
    rootLength = string.len(Ui.ROOT_FRAME) + 1,
    sites = {
        ---@param site Site
        show = function(event, site)
            Sites.highlight_site(site)
        end,
        ---@param site Site
        edit = function(event, site)
            Ui.edit_site(site, game.players[event.player_index])
        end,
        rename = function(event, site)
            Ui.rename_callback(site, game.players[event.player_index])    
        end
    },
}

local function create_root(player)
    return mod_gui.get_frame_flow(player).add {
        type = 'frame',
        name = Ui.ROOT_FRAME,
    }
end

local function get_root(player)
    return mod_gui.get_frame_flow(player)[Ui.ROOT_FRAME] or create_root(player)
end

---@param ticks integer
---@return string
local function ticks_to_time(ticks)
    local sec = math.floor(ticks / 60)
    local min = math.floor(sec / 60)
    local hour = math.floor(min / 60)
    min = (min % 60)
    sec = (sec % 60)
    if min < 10 then min = '0' .. min end
    if sec < 10 then sec = '0' .. sec end
    return hour .. ':' .. min .. ':' .. sec
end

local SI_STRINGS = {'', 'k', 'M', 'G', 'T', 'P', 'E', 'Z'}

---@param integer integer
---@return string
local function int_to_exponent_string(integer)
    local i = 1
    while integer > 100 do
        integer = integer / 1000
        i = i + 1
    end
    return string.format('%.2f', integer) .. SI_STRINGS[i]
end

function Ui.init(player)
    local root = mod_gui.get_frame_flow(player)[Ui.ROOT_FRAME]
    if root ~= nil then
        root.destroy()
    end
    root = create_root(player)
    Ui.update_sites()
end

function Ui.update()
    for key, player in pairs(game.players) do
        Ui.update_sites(player)
    end
end

function Ui.update_sites(player)
    local root = get_root(player)

    if root.sites then
        root.sites.destroy()
    end

    local gui = root.add {
        type = 'table',
        name = 'sites',
        style = 'statistics_element_table',
        column_count = 5,
        draw_horizontal_line_after_headers = true,
    }

    gui.add { type = 'label', style = 'caption_label', caption = '' }
    gui.add { type = 'label', style = 'caption_label', caption = {'external-dashboard.ui-site-name'} }
    gui.add { type = 'label', style = 'caption_label', caption = {'external-dashboard.ui-site-amount'} }
    gui.add { type = 'label', style = 'caption_label', caption = {'external-dashboard.ui-site-initial-amount'} }
    gui.add { type = 'label', style = 'caption_label', caption = '' }

    for surface_index, types in pairs(Sites.get_sites_from_cache_all()) do
        for type, sites in pairs(types) do
            for siteKey, site in pairs(sites) do
                gui.add { type = 'label', caption = '[item=' .. site.type .. ']' }
                gui.add { type = 'label', caption = site.name }
                gui.add { type = 'label', caption = int_to_exponent_string(site.amount) }
                gui.add { type = 'label', caption = int_to_exponent_string(site.initial_amount) }

                local buttons = gui.add { type = 'flow', direction = 'horizontal' }
                -- buttons.add { type = 'sprite-button', style = 'tool_button', sprite = 'utility/show_tags_in_map_view', name = Ui.ROOT_FRAME .. '-sites-show-' .. surface_index .. '-' .. type .. '-' .. siteKey }
                buttons.add { type = 'sprite-button', style = 'mini_button', sprite = 'utility/rename_icon_small_black', name = Ui.ROOT_FRAME .. '-sites-edit-' .. surface_index .. '-' .. type .. '-' .. siteKey }
            end
        end
    end
end

---@param site Site
---@param player LuaPlayer
function Ui.edit_site(site, player)
    local window = Window.create(player, site.name)

    local table = window.add { type = 'table', column_count = 2 }
    table.add { type = 'label', caption = {'external-dashboard.ui-colon', {'external-dashboard.ui-site-surface'}} }
    table.add { type = 'label', caption = game.surfaces[site.surface].name .. ' [' .. site.surface .. ']' }
    table.add { type = 'label', caption = {'external-dashboard.ui-colon', {'external-dashboard.ui-site-tiles'}} }
    table.add { type = 'label', caption = #site.positions }
    table.add { type = 'label', caption = {'external-dashboard.ui-colon', {'external-dashboard.ui-site-amount'}} }
    table.add { type = 'label', caption = int_to_exponent_string(site.amount) }
    table.add { type = 'label', caption = {'external-dashboard.ui-colon', {'external-dashboard.ui-site-initial-amount'}} }
    table.add { type = 'label', caption = int_to_exponent_string(site.initial_amount) }
    table.add { type = 'label', caption = {'external-dashboard.ui-colon', {'external-dashboard.ui-site-created'}} }
    table.add { type = 'label', caption = ticks_to_time(site.since) .. ' (' .. ticks_to_time(game.tick - site.since) ..' ago)' }

    window.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }
    
    local rename = window.add { type = 'flow', name = 'rename' }
    rename.add {
        type = 'textfield',
        name = Ui.ROOT_WINDOW .. '-name',
        text = site.name,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
    }
    rename.add { type = 'button', caption = {'external-dashboard.ui-ok'}, style = 'item_and_count_select_confirm', name =  Ui.ROOT_FRAME .. '-sites-rename-' .. site.surface .. '-' .. site.type .. '-' .. site.index}

    window.add { type = 'line', style = 'inside_shallow_frame_with_padding_line' }


    local buttons = window.add { type = 'flow' }
    buttons.add { type = 'sprite-button', tooltip = {'external-dashboard.ui-site-show-tooltip'}, sprite = 'utility/show_tags_in_map_view', name = Ui.ROOT_FRAME .. '-sites-show-' .. site.surface .. '-' .. site.type .. '-' .. site.index }
end

---@param site Site
---@param player LuaPlayer
function Ui.rename_callback(site, player)
    local textfield = Window.get(player)['rename'][Ui.ROOT_WINDOW .. '-name']

    site.name = textfield.text

    Ui.edit_site(site, player)
    Ui.update_sites(player)
end

function on_player_created(event)
    Ui.init(event.player)
end

function on_player_joined_game(event)
    Ui.init(event.player)
end

function on_gui_click(event)
    local name = event.element.name
    if name and string.sub(name, 0, BUTTON_ROUTER.rootLength) == BUTTON_ROUTER.root then
        local sub = string.sub(name, BUTTON_ROUTER.rootLength + 1)

        local iter = string.gmatch('-' .. sub, '-(%w+)')
        local command = iter()

        if command == 'sites' then
            local func = iter()
            -- move remaining matches into p
            local p = {}
            for v in iter do table.insert(p, v) end
            local surfaceKey = tonumber(p[1])
            local siteKey = tonumber(p[#p])
            local typeKey = table.concat(p, '-', 2, #p - 1)

            local site = Sites.get_site_from_cache(surfaceKey, typeKey, siteKey)

            if site == nil then
                game.players[event.player_index].print('Cannot find site Surface ' ..
                    surfaceKey .. ', Type ' .. typeKey .. ', Index ' .. siteKey)
            else
                BUTTON_ROUTER.sites[func](event, site)
            end
        elseif command == 'window' then
            local next = iter()
            if next == 'close' then
                Window.close(game.players[event.player_index])
            end
        end
    end
end

function on_gui_closed(event)
    if event.element then
        if event.element.name == Ui.ROOT_WINDOW then
            Window.close(game.players[event.player_index])
        end
    end
end

script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_nth_tick(600, function(event) Ui.update() end) -- todo adjust
script.on_event({ defines.events.on_gui_click }, on_gui_click)
script.on_event({ defines.events.on_gui_closed }, on_gui_closed)
