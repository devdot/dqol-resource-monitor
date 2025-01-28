
---@type {request: function, callback: table<uint, {callback: fun(result: string, meta: table, event: table), meta: table}>}
Translation = {
    -- for now translations are not stored but only directed back
    callback = {},
    -- maybe we need to store callbacks in storage?
}

---@param string LocalisedString
---@param callback function
---@param meta table?
---@param player LuaPlayer?
---@returns boolean
function Translation.request(string, callback, meta, player)
    if player == nil then
        local _key, _player = pairs(game.players)(game.players, nil)
        player = _player or nil
    end
    if player == nil then
        log('Failed requesting translation without player: ' .. serpent.line(string))
        return false
    end

    local id = player.request_translation(string)

    if id == nil then
        log('Failed requesting translation: ' .. serpent.line(string))
        return false
    end

    Translation.callback[id] = { callback = callback, meta = meta or {} }
    return true
end

local function translation_callback(event)
    local data = Translation.callback[event.id] or nil

    -- many mods might ask for translations, we only care about those that we requested
    if data == nil then return end

    data.callback(event.result, data.meta, event)

    Translation.callback[event.id] = nil
end

script.on_event(defines.events.on_string_translated, translation_callback)
