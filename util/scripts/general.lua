_G.perel = perel or {}

---Returns the undo action associated with this entity
---@param actions UndoRedoAction[]
---@param entity LuaEntity
---@return uint32? action_index
perel.find_build_action = function(actions, entity)
  for a, action in pairs(actions) do
    if action.type == "built-entity" and
      action.surface_index == entity.surface_index and
      action.target.name == entity.name and
      action.target.position.x == entity.position.x and
      action.target.position.y == entity.position.y then
      return a
    end
  end
end

---Returns the undo item and action associated with this entity
---@param stack LuaUndoRedoStack
---@param entity LuaEntity
---@return uint32? item_index, uint32? action_index
perel.find_build_item = function(stack, entity)
  if not stack then return end
  for i = 1, stack.get_undo_item_count() do
    local action_index = perel.find_build_action(stack.get_undo_item(i), entity)
    if action_index then return i, action_index end
  end
end

-- returns the longest edge of the bounding box, or the length of a side for a square entity
---@param prototype LuaEntityPrototype
---@return double size
perel.get_side_length = function(prototype)
  local box = prototype.collision_box
  local dx, dy = box.right_bottom.x - box.left_top.x, box.right_bottom.y - box.left_top.y
  return dx > dy and dx or dy
end

--- returns the direction from a to b, assuming the two are in a straight line
---@param a MapPosition
---@param b MapPosition
---@return defines.direction
perel.get_direction = function(a, b)
  return math.abs(a.x - b.x) > math.abs(a.y - b.y) and (a.x < b.x and 4 or 12) or (a.y < b.y and 8 or 0)
end