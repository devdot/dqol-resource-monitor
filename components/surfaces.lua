Surfaces = {
    storage = {},
    surface = {},
}

---@alias SurfaceResources ResourceIdentifier[]
---@alias Surface {id: integer, resources: SurfaceResources, tracking: boolean, hidden: boolean}

---@alias GlobalSurfaces {surface_storage: Surface[]|nil}

local finish_generate_surface_list = {}

local function finish_generate_from_game()
    -- filter the list (remove surfaces that do not exist anymore)
    local list = {}
    for _, surface in pairs(finish_generate_surface_list) do if game.get_surface(surface.id) then table.insert(list, surface) end end

    local hide = {
        ['aai-signals'] = 'aai-signal-transmission',
        ['thruster-control-behavior'] = 'thruster-control-behavior',
    }

    -- find a way to work this queue more performatly?
    for _, surface in pairs(list) do
        local game_surface = game.surfaces[surface.id]
        if game_surface.platform ~= nil then
            surface.hidden = true
            surface.tracking = false
            goto continue
        end

        if hide[game_surface.name] ~= nil and script.active_mods[hide[game_surface.name]] then
            surface.hidden = true
            surface.tracking = false
            goto continue
        end

        if script.active_mods['minime'] then
            if string.sub(game_surface.name, 1, 7) == 'minime_' then
                surface.hidden = true
                surface.tracking = false
                goto continue
            end 
        end
        
        if script.active_mods['space-exploration'] then
            -- this might need fixing once SE releases for 2.0
            local zone = remote.call("space-exploration", "get_zone_from_surface_index", { surface_index = surface.id })
            local type = zone and zone.type

            if _DEBUG then
                game.print('Used SE universe to find zone type for ' .. surface.id .. ': ' .. (type or 'nil'))
            end

            if type == nil then
                surface.hidden = true
                surface.tracking = false
            else
                surface.hidden = false
                surface.tracking = true
            end
        end

        ::continue::
    end
    finish_generate_surface_list = {}
end

---@param surface Surface
function Surfaces.storage.insert(surface)
    storage.surface_storage[surface.id] = surface
end

---@param id integer
function Surfaces.storage.remove(id)
    storage.surface_storage[id] = nil
end

---@param id integer
---@return Surface?
function Surfaces.storage.getById(id)
    finish_generate_from_game()
    return storage.surface_storage[id] or nil
end

---@return Surface[]
function Surfaces.storage.all()
    finish_generate_from_game()
    return storage.surface_storage or {}
end

function Surfaces.storage.softInitialize()
    if storage.surface_storage == nil then
        Surfaces.storage.reset()
    end    
end

function Surfaces.storage.reset()
    storage.surface_storage = {}
end

function Surfaces.getVisibleSurfaces()
    finish_generate_from_game()
    local list = {}
    for _, surface in pairs(Surfaces.storage.all()) do
        if surface.hidden == false then
            table.insert(list, surface)
        end
    end
    return list
end

---@param luaSurface LuaSurface
---@return Surface
function Surfaces.generateFromGame(luaSurface)
    local surface = {
        id = luaSurface.index,
        resources = {},
        tracking = settings.global['dqol-resource-monitor-site-auto-scan'].value,
        hidden = false,
    }

    if _DEBUG then
        game.print('Added surface ' .. serpent.line(surface))
    end

    -- add to the finish generate list
    table.insert(finish_generate_surface_list, surface)

    Surfaces.storage.insert(surface)
    Surfaces.surface.updateResources(surface)
    return surface
end

function Surfaces.initialize()
    for index, luaSurface in pairs(game.surfaces) do
        local surface = Surfaces.storage.getById(luaSurface.index)

        if surface == nil then
            Surfaces.generateFromGame(luaSurface)
        end
    end
end

function Surfaces.updateAll()
    for index, surface in pairs(Surfaces.storage.all()) do
        Surfaces.surface.updateResources(surface)
    end
end

---@param id integer
function Surfaces.surface.delete(id)
    Surfaces.storage.remove(id)
end

---@param surface Surface
---@return string|LocalisedString
function Surfaces.surface.getName(surface)
    local luaSurface = game.surfaces[surface.id] or {}
    if luaSurface.planet then
        return luaSurface.planet.prototype.localised_name
    end
    return luaSurface.localised_name or luaSurface.name or ''
end

---@param id integer
---@return string|LocalisedString
function Surfaces.surface.getNameById(id)
    local surface = Surfaces.storage.getById(id)
    if surface == nil then return '' end
    return Surfaces.surface.getName(surface)
end

---@param surface_id integer
---@return string
function Surfaces.surface.getIconString(surface_id)
    return '[planet=' .. (game.surfaces[surface_id].name or '') .. ']'
end

---@param surface Surface
function Surfaces.surface.updateResources(surface)
    local newTypes = {}

    -- get all the sites on this surface
    local types = Sites.storage.getSurfaceSubList(surface.id)
    
    -- go through the types to ensure the order is always the same
    for _, resource in pairs(Resources.types) do
        if types[resource.resource_name] ~= nil and table_size(types[resource.resource_name]) > 0 then
            table.insert(newTypes, resource.resource_name)
        end
    end

    surface.resources = newTypes
end

function Surfaces.onInitMod()
    Surfaces.storage.reset()
    Surfaces.initialize()
end

function Surfaces.on_configuration_changed()
    Surfaces.storage.softInitialize()
    Surfaces.initialize()
    Surfaces.updateAll()
end
