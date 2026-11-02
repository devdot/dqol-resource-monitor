
---@type {request: function, register: function, handlers: table<string, fun(result: string, meta: table, event: table)>}
Translation = {
    -- handlers are registered by name at load time, pending requests live in storage
    handlers = {},
}

---@param name string
---@param handler fun(result: string, meta: table, event: table)
function Translation.register(name, handler)
    Translation.handlers[name] = handler
end

---@param string string|string[] {1: string, 2: string}
---@param handler string name passed to Translation.register
---@param meta table?
---@param player LuaPlayer?
---@returns boolean
function Translation.request(string, handler, meta, player)
    if type(string) ~= 'string' then
        if meta == nil then
            meta = { domain = string[1], type = string[2] }
        end

        string = string[1] .. '.' .. string[2]
    end

    -- now transform into localized string
    string = {string}

    if player == nil then
        local _key, _player = pairs(game.players)(game.players, nil)
        player = _player or nil
    end
    if player == nil then
        -- log('Failed requesting translation without player: ' .. serpent.line(string))
        return false
    end

    local id = player.request_translation(string)

    if id == nil then
        log('Failed requesting translation: ' .. serpent.line(string))
        return false
    end

    -- pending requests must be in storage: a client joining mid-flight has to apply the same results as the server
    storage.translation_requests = storage.translation_requests or {}
    storage.translation_requests[id] = { handler = handler, meta = meta or {} }
    return true
end

local function translation_callback(event)
    local data = storage.translation_requests and storage.translation_requests[event.id] or nil

    -- many mods might ask for translations, we only care about those that we requested
    if data == nil then return end

    storage.translation_requests[event.id] = nil

    local handler = Translation.handlers[data.handler]
    if handler ~= nil then
        handler(event.result, data.meta, event)
    end
end

script.on_event(defines.events.on_string_translated, translation_callback)
