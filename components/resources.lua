---@alias ResourceType {type: 'item' | 'fluid', name: string, resource_name: string}

---@type {types: table<string, ResourceType>, boot: function, on_configuration_changed: function}
Resources = {
    types = {},
}

local function generate_resources()
    for key, resource in pairs(game.get_filtered_entity_prototypes({ { filter = 'type', type = 'resource' } }) or {}) do
        -- expect resource to be LuaEntityPrototype
        for key, product in pairs(resource.mineable_properties.products) do
            Resources.types[resource.name] = {
                type = product.type,
                name = product.name,
                resource_name = resource.name,
            }
        end
    end

    -- write to global cache
    global.resources = {
        types = Resources.types,
    }    
end

function Resources.boot()
    -- check if we can generate now
    if game ~= nil then
        generate_resources()
    end
    
    -- read from cache
    if global.resources ~= nil and global.resources.types ~= nil then
        Resources.types = global.resources.types
    end
end

Resources.on_configuration_changed = generate_resources
