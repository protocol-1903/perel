require "__perel__.util.scripts.general"

--- returns any fluidbox connected neighbours. by default only includes normal connections
---@param entity LuaEntity 
---@param include_undergrounds? boolean whether or not to include underground connections, default false
---@return LuaEntity[] neighbours
perel.get_fluidbox_neighoburs = function(entity, include_undergrounds)
  local neighbours = {}
  for i = 1, #entity.fluidbox do
    for _, pipe_connection in pairs(entity.fluidbox.get_pipe_connections(i)) do
      if pipe_connection.target and (include_undergrounds and pipe_connection.connection_type ~= "linked" or pipe_connection.connection_type == "normal") then
        neighbours[#neighbours+1] = pipe_connection.target.owner
      end
    end
  end
  return neighbours
end

--- returns the bitmask that represents the fluid connections of this entity. only includes connections that are valid and in use. may return nonsensical values when used on entities that do not have pipe-like connections
---@param entity LuaEntity 
---@param include_undergrounds? boolean whether or not to include underground connections, default false
---@return LuaEntity[] neighbours
perel.get_pipe_connection_bitmask = function(entity, include_undergrounds)
  local mask = 0
  for _, neighbour in pairs(perel.get_fluidbox_neighoburs(entity, include_undergrounds)) do
    mask = mask + 2 ^ (perel.get_direction(entity.position, neighbour.position) / 4)
  end
  return mask
end

--- stores all of the normal connection categories found on an entity as a boolean dictionary. lazy loaded as required
---@type table<EntityID, table<string, boolean>>
perel.entity_connection_categories = {}

--- returns the connection category dictionary for an entity, and creates it if it don't already exist
---@param prototype LuaEntityPrototype
---@return table<string, boolean>
perel.get_entity_connection_categories = function(prototype)
  if perel.entity_connection_categories[prototype.name] then return perel.entity_connection_categories[prototype.name] end
  perel.entity_connection_categories[prototype.name] = {}
  for _, fluidbox in pairs(prototype.fluidbox_prototypes) do
    for _, pipe_conneciton in pairs(fluidbox.pipe_connections) do
      if pipe_conneciton.connection_type == "normal" then
        for _, category in pairs(pipe_conneciton.connection_category) do
          perel.entity_connection_categories[prototype.name][category] = true
        end
      end
    end
  end
  return perel.entity_connection_categories[prototype.name]
end

--- returns the neighbours that might connect to the entity's fluidboxes.
--- may return duplicate entries if an entity collides with multiple pipe connection targets
---@param entity LuaEntity
---@param categories? table<string, boolean>
---@return LuaEntity[] neighbours
perel.get_possible_fluidbox_neighbours = function(entity, categories)
  local neighbours = {}
  categories = categories or perel.get_entity_connection_categories(entity.type == "entity-ghost" and entity.ghost_prototype or entity.prototype)
  if not next(categories) then return {} end
  for i = 1, #entity.fluidbox do
    for _, pipe_connection in pairs(entity.fluidbox.get_pipe_connections(i)) do
      if pipe_connection.target and pipe_connection.connection_type == "normal" then
        neighbours[#neighbours+1] = pipe_connection.target.owner
      elseif not pipe_connection.target then
        for _, e in pairs(entity.surface.find_entities_filtered{
          position = pipe_connection.target_position
        }) do
          for category in pairs(perel.get_entity_connection_categories(e.type == "entity-ghost" and e.ghost_prototype or e.prototype)) do
            if categories[category] then
              neighbours[#neighbours+1] = e
              break
            end
          end
        end
      end
    end
  end
  return neighbours
end

return perel