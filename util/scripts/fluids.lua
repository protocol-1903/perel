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

return perel