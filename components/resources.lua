---@alias ResourceIdentifier string
--   the name of a prototype of ResourceEntityPrototype
---@alias ResourceType { resource_name: ResourceIdentifier, category: string, infinite: boolean, hidden: boolean, tracking_ignore: boolean, color: Color, products: ProductIdentifier[], loose_merge: boolean, translated_name: string}

---@alias ProductIdentifier string
--    the name of a prototype, is unqiue across all entity types
---@alias ProductType {type: 'item' | 'fluid', name: ProductIdentifier, produced_by: ResourceIdentifier[]}

---@type {types: table<ResourceIdentifier, ResourceType>, products: table<ProductIdentifier, ProductType>, boot: function, bootPlayer: function, getProduct: function, getProducts: function, getIconString: function, getSpriteString: function, getSignalId: function, cleanResources: function, cleanProducts: function, on_configuration_changed: function}
Resources = {
    types = {},
    products = {},
}

local function generate_color(resource_name)
    local proto = prototypes.entity[resource_name]

    if proto and proto.map_color then
        return proto.map_color
    end

    return { r = .5, b = .5, g = .5 }
end

---@param resource ResourceType
local function resource_postprocess(resource)
    if table_size(resource.products) == 0 then
        resource.tracking_ignore = true
    end

    if resource.category == 'se-core-mining' then
        resource.hidden = true
        resource.tracking_ignore = true
    end

    if resource.resource_name == 'scrap' then
        resource.loose_merge = true
    end

    if script.active_mods['FunkedOre'] or script.active_mods['DivOresity'] then
        -- funked ore breaks usual conventions for all resources, therefore we need to break strict merges
        resource.loose_merge = true;
    end
end

---@param resource LuaEntityPrototype
---@returns boolean
local function resource_is_loose_merge(resource)
    -- see if collision_box is smaller than {left_top = {x = -0.5, y = -0.5}, right_bottom = {x = 0.5, y = 0.5}}
    local box = resource.collision_box or {}
    local left_top = box.left_top or {}
    local right_bottom = box.right_bottom or {}

    if (left_top.x and left_top.x >= -0.5)
        and (left_top.y and left_top.y >= -0.5)
        and (right_bottom.x and right_bottom.x <= 0.5)
        and (right_bottom.y and right_bottom.y <= 0.5)
    then
        return false
    end

    return true
end

local function save_to_storage()
    storage.resources = {
        types = Resources.types,
        products = Resources.products,
    }
end

local function resource_translated(string, meta, event)
    if Resources.types[meta.type] ~= nil then
        Resources.types[meta.type].translated_name = string
        log('Translated ' .. meta.type .. ' to ' .. string)
        save_to_storage()
    end
end

local function generate_resources()
    Resources.types = {}
    Resources.products = {}

    for key, resource in pairs(prototypes.get_entity_filtered({ { filter = 'type', type = 'resource' } }) or {}) do
        -- expect resource to be LuaEntityPrototype
        log('Add resource ' .. resource.name .. ' of category ' .. resource.resource_category)
        Resources.types[resource.name] = {
            resource_name = resource.name,
            category = resource.resource_category,
            infinite = resource.infinite_resource or false,
            hidden = false,
            tracking_ignore = false,
            loose_merge = resource_is_loose_merge(resource),
            color = generate_color(resource.name),
            products = {},
            translated_name = resource.name,
        }

        for key, product in pairs(resource.mineable_properties.products or {}) do
            -- filter unwanted types
            if product.type ~= 'research-progress' then
                -- create the product if it does not exist
                if Resources.products[product.name] == nil then
                    log('Add new product ' .. product.name .. ' for resource ' .. resource.name)
                    Resources.products[product.name] = {
                        type = product.type,
                        name = product.name,
                        produced_by = { resource.name },
                    }
                else
                    log('Add existing product ' .. product.name .. ' for resource ' .. resource.name)
                    table.insert(Resources.products[product.name].produced_by, resource.name)
                end
    
                -- add to the resource
                table.insert(Resources.types[resource.name].products, product.name)
            end
        end
    end

    -- process the resources again
    for _, resource in pairs(Resources.types) do
        resource_postprocess(resource)
    end

    -- request translations for all resources
    for _, resource in pairs(Resources.types) do
        Translation.request({'entity-name.' .. resource.resource_name}, resource_translated, {type = resource.resource_name})
    end

    -- write to global cache
    save_to_storage()

    Sites.storage.clean()
end

---@param resource ResourceIdentifier
---@returns table<ProductIdentifier, ProductType>
function Resources.getProducts(resource)
    if Resources.types[resource] then
        local products = {}
        for _, key in pairs(Resources.types[resource].products) do
            products[key] = Resources.products[key]
        end
        return products
    end
    return {}
end

---@param resource ResourceIdentifier
---@returns ProductType?
function Resources.getProduct(resource)
    if Resources.types[resource] then
        return Resources.products[Resources.types[resource].products[1]]
    end
    return nil
end

---@param resource ResourceIdentifier
---@returns string
function Resources.getIconString(resource)
    if helpers.is_valid_sprite_path('entity/' .. resource) then
        return '[img=entity/' .. resource .. ']'
    end

    local product = Resources.getProduct(resource)
    if product then
        return '[' .. product.type .. '=' .. product.name .. ']'
    else
        -- does not exist!
        return '[img=entity/' .. resource .. ']'
    end
end

---@param resource ResourceIdentifier
---@returns string
function Resources.getSpriteString(resource)
    if helpers.is_valid_sprite_path('entity/' .. resource) then
        return 'entity/' .. resource
    end

    local product = Resources.getProduct(resource)
    if product then
        return product.type .. '/' .. product.name
    else
        -- does not exist!
        return 'utility/green_dot'
    end
end

---@param resource ResourceIdentifier
---@returns {type: string, name: string}
function Resources.getSignalId(resource)
    local product = Resources.getProduct(resource)
    if product then
        return {
            type = product.type,
            name = product.name,
        }
    else
        -- invalid
        return { type = 'virtual', name = 'signal-dot' }
    end
end

function Resources.boot()
    -- check if we can generate now
    if game ~= nil then
        generate_resources()
    end
    
    -- read from cache
    if storage.resources ~= nil and storage.resources.types ~= nil then
        Resources.types = storage.resources.types
        Resources.products = storage.resources.products
    end
end

---@param player LuaPlayer
function Resources.bootPlayer(player)
    -- this is currently required, so that resources can be translated in new single player games
    -- perhaps find a better way to figure out that a game has been started
    for _, resource in pairs(Resources.types) do
        if resource.translated_name ~= resource.resource_name and resource.translated_name ~= 'entity-name.' .. resource.resource_name then
            return
        end
    end
    
    log('Re-run resource generation from player ' .. player.index)
    generate_resources()
end

---@return table<ResourceIdentifier, ResourceType>
function Resources.cleanResources()
    local types = {}
    for key, type in pairs(Resources.types) do
        local insert = true

        if type.hidden then
            insert = false
        end

        if insert then
            types[key] = type
        end
    end
    return types
end

---@return table<ProductIdentifier , ProductType>
function Resources.cleanProducts()
    local products = {}
    for key, product in pairs(Resources.products) do
        local insert = true

        if Resources.types[product.produced_by[1]].hidden then
            insert = false
        end

        if insert then
            products[key] = product
        end
    end
    return products
end

Resources.on_configuration_changed = generate_resources

