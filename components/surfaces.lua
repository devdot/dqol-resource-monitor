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
    for _, surface in pairs(finish_generate_surface_list) do if game.surfaces[surface.id] then table.insert(list, surface) end end

    -- find a way to work this queue more performatly?
    for _, surface in pairs(list) do
        if script.active_mods['space-exploration'] then
            local zone = remote.call("space-exploration", "get_surface_type", { surface_index = surface.id })

            if _DEBUG then
                game.print('Used SE universe to find zone type for ' .. surface.id .. ': ' .. (zone or 'nil'))
            end

            if zone == nil then
                surface.hidden = true
                surface.tracking = false
            else
                surface.hidden = false
                surface.tracking = true
            end
        end
    end
    finish_generate_surface_list = {}
end

---@param surface Surface
function Surfaces.storage.insert(surface)
    global.surface_storage[surface.id] = surface
end

---@param id integer
function Surfaces.storage.remove(id)
    global.surface_storage[id] = nil
end

---@param id integer
---@return Surface?
function Surfaces.storage.getById(id)
    finish_generate_from_game()
    return global.surface_storage[id] or nil
end

---@return Surface[]
function Surfaces.storage.all()
    finish_generate_from_game()
    return global.surface_storage or {}
end

function Surfaces.storage.softInitialize()
    if global.surface_storage == nil then
        Surfaces.storage.reset()
    end    
end

function Surfaces.storage.reset()
    global.surface_storage = {}
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
---@return string
function Surfaces.surface.getName(surface)
    local luaSurface = game.surfaces[surface.id] or {}
    local name = luaSurface.name or ''
    if name == 'nauvis' then name = 'Nauvis' end
    return name
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
