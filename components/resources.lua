---@alias ResourceIdentifier string
--   the name of a prototype of ResourceEntityPrototype
---@alias ResourceType { resource_name: ResourceIdentifier, category: string, infinite: boolean, hidden: boolean, tracking_ignore: boolean, color: Color, products: ProductIdentifier[]}

---@alias ProductIdentifier string
--    the name of a prototype, is unqiue across all entity types
---@alias ProductType {type: 'item' | 'fluid', name: ProductIdentifier, produced_by: ResourceIdentifier[]}

---@type {types: table<ResourceIdentifier, ResourceType>, products: table<ProductIdentifier, ProductType>, looseMerge: table<string, boolean>, boot: function, getProduct: function, getProducts: function, getIconString: function, getSpriteString: function, getSignalId: function, cleanResources: function, cleanProducts: function, on_configuration_changed: function}
Resources = {
    types = {},
    products = {},
    looseMerge = {
        ['crude-oil'] = true,
        ['phosphate-rock'] = true, -- py
        ['ore-titanium'] = true, -- py, not working as expected
    }
}

local function generate_color(resource_name)
    local proto = game.entity_prototypes[resource_name]

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
end

local function generate_resources()
    Resources.types = {}
    Resources.products = {}

    for key, resource in pairs(game.get_filtered_entity_prototypes({ { filter = 'type', type = 'resource' } }) or {}) do
        -- expect resource to be LuaEntityPrototype
        log('Add resource ' .. resource.name .. ' of category ' .. resource.resource_category)
        Resources.types[resource.name] = {
            resource_name = resource.name,
            category = resource.resource_category,
            infinite = resource.infinite_resource or false,
            hidden = false,
            tracking_ignore = false,
            color = generate_color(resource.name),
            products = {},
        }

        for key, product in pairs(resource.mineable_properties.products or {}) do
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

    -- process the resources again
    for _, resource in pairs(Resources.types) do
        resource_postprocess(resource)
    end

    -- write to global cache
    global.resources = {
        types = Resources.types,
        products = Resources.products,
    }
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
    local product = Resources.getProduct(resource)
    if product then
        return '[' .. product.type .. '=' .. product.name .. ']'
    else
        -- does not exist!
        return '[img=resource/' .. resource .. ']'
    end
end

---@param resource ResourceIdentifier
---@returns string
function Resources.getSpriteString(resource)
    local product = Resources.getProduct(resource)
    if product then
        return product.type .. '/' .. product.name
    else
        -- does not exist!
        return 'resource/' .. resource
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
        return { type = '', name = '' }
    end
end

function Resources.boot()
    -- check if we can generate now
    if game ~= nil then
        generate_resources()
    end
    
    -- read from cache
    if global.resources ~= nil and global.resources.types ~= nil then
        Resources.types = global.resources.types
        Resources.products = global.resources.products
    end
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
            products[key] = type
        end
    end
    return products
end

Resources.on_configuration_changed = generate_resources

