-- scripts.storage-handler.lua
-- Simple, robust tracker for static entities. Tracks by unit_number in storage.
-- Usage: local handler = create_storage_handler(config)
-- Config: {entity_name = "required-name", storage_prefix = "optional-prefix-for-storage-keys"}

local function create_storage_handler(config)
    config = config or {}
    local handler = {
        entity_name = config.entity_name,
        storage_prefix = config.storage_prefix or "default",
        entities_key = (config.storage_prefix .. "_entities"):gsub("^_", ""),  -- e.g., "fishing_entities"
        name_set = {}  -- Simple cache for quick checks
    }
    handler.name_set[handler.entity_name] = true  -- Single-name set for efficiency

    -- Ensure storage tables exist (lazy init)
    function handler:initialize_storage()
        storage[self.entities_key] = storage[self.entities_key] or {}
    end

    -- Add entity to tracked list
    function handler:register(entity)
        if not entity or not entity.valid or not self.name_set[entity.name] then return end
        self:initialize_storage()
        -- Store as {entity = entity} for easy access; supports lazy migration
        storage[self.entities_key][entity.unit_number] = { entity = entity }
    end

    -- Remove entity from tracked list
    function handler:unregister(unit_number)
        if unit_number and storage[self.entities_key] then
            storage[self.entities_key][unit_number] = nil
        end
    end

    -- Scan all surfaces for existing entities and register them
    function handler:scan_and_register()
        self:initialize_storage()
        for _, surface in pairs(game.surfaces) do
            local entities = surface.find_entities_filtered { name = self.entity_name }
            for _, entity in ipairs(entities) do
                self:register(entity)
            end
        end
    end

    -- Validate and get entity data (handles invalid entities and old migration)
    -- Returns data or nil if invalid/unrecoverable
    local function validate_data(unit_number)
        local data = storage[handler.entities_key][unit_number]
        -- Lazy migration: if old direct entity format (pre-refactor), convert
        if type(data) ~= "table" then
            if data and data.valid then
                data = { entity = data }
                storage[handler.entities_key][unit_number] = data
            else
                handler:unregister(unit_number)
                return nil
            end
        end
        local entity = data.entity
        if not entity or not entity.valid then
            handler:unregister(unit_number)
            return nil
        end
        return data
    end

    -- Public method for getting valid data (used by rolling update)
    function handler:get_valid_data(unit_number)
        if not storage[self.entities_key] then return nil end
        local data = storage[self.entities_key][unit_number]
        if not data then return nil end

        -- Lazy migration
        if type(data) ~= "table" then
            if data and data.valid then
                data = { entity = data }
                storage[self.entities_key][unit_number] = data
            else
                self:unregister(unit_number)
                return nil
            end
        end

        local entity = data.entity
        if entity and entity.valid then
            return data
        else
            self:unregister(unit_number)
            return nil
        end
    end

    -- Iterator over all valid tracked entities (pre-validates for simplicity, no coroutines)
    function handler:iterate_valid_entities()
        self:initialize_storage()
        local valid_entries = {}
        for unit_number, _ in pairs(storage[self.entities_key]) do
            local data = validate_data(unit_number)
            if data then
                table.insert(valid_entries, {unit_number, data})
            end
        end
        local i = 0
        return function()
            i = i + 1
            if i > #valid_entries then return nil end
            return valid_entries[i][1], valid_entries[i][2]
        end
    end

    return handler
end

return { create_storage_handler = create_storage_handler }