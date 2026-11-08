-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@class (partial) PEREL
---@field find_build_action fun(actions: UndoRedoAction[], entity: LuaEntity): uint32? -- Returns the undo action associated with this entity
---@field find_build_item fun(stack?: LuaUndoRedoStack, entity: LuaEntity): [uint32?, uint32?] -- Returns the undo item and action associated with this entity
---@field get_side_length fun(prototype: LuaEntityPrototype): double -- Returns the longest edge of the bounding box, or the length of a side for a square entity
---@field get_direction fun(a: MapPosition, b: MapPosition): defines.direction -- Returns the direction from a to b, assuming the two are in a straight line
---@field insert_tag fun(ghost: LuaEntity, table: string, tag: any, key: string|uint?) -- Appends the tag to the specified subtable, optionally at the applied index
---@field set_tag fun(ghost: LuaEntity, key: string, tag: any) -- Sets the specified key to the tag
---@field get_tag fun(ghost: LuaEntity, key: string): any? -- Gets a tag from the entity
perel = perel or {}

---Returns the undo action associated with this entity
---@param actions UndoRedoAction[]
---@param entity LuaEntity
---@return uint32? action_index
perel.find_build_action = function(actions, entity)
  local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
  for a, action in pairs(actions) do
    if action.type == "built-entity" and
      action.surface_index == entity.surface_index and
      action.target.name == name and
      (not action.target.quality or action.target.quality == entity.quality) and
      action.target.position.x == entity.position.x and
      action.target.position.y == entity.position.y and
      (not action.target.direction or action.target.direction == entity.direction) then
      return a
    end
  end
end

---Returns the undo item and action associated with this entity
---@param stack? LuaUndoRedoStack
---@param entity LuaEntity
---@return uint32? item_index, uint32? action_index
perel.find_build_item = function(stack, entity)
  if not stack then return end
  for i = 1, stack.get_undo_item_count() do
    local action_index = perel.find_build_action(stack.get_undo_item(i), entity)
    if action_index then return i, action_index end
  end
end

---Returns the longest edge of the bounding box, or the length of a side for a square entity
---@param prototype LuaEntityPrototype
---@return double size
perel.get_side_length = function(prototype)
  local box = prototype.collision_box
  local dx, dy = box.right_bottom.x - box.left_top.x, box.right_bottom.y - box.left_top.y
  return dx > dy and dx or dy
end

---Returns the direction from a to b, assuming the two are in a straight line
---@param a MapPosition
---@param b MapPosition
---@return defines.direction
perel.get_direction = function(a, b)
  ---@diagnostic disable-next-line: return-type-mismatch
  return math.abs(a.x - b.x) > math.abs(a.y - b.y) and (a.x < b.x and 4 or 12) or (a.y < b.y and 8 or 0)
end

---Appends the tag to the specified subtable, optionally at the applied index
---@param ghost LuaEntity
---@param table string
---@param tag any
---@param key? string|uint optional key instead of appending
perel.insert_tag = function(ghost, table, tag, key)
  if not ghost or not ghost.valid or ghost.type ~= "entity-ghost" then return end
  local tags = ghost.tags or {}
  tags.perel = tags.perel or {}
  tags.perel[table] = tags.perel[table] or {}
  tags.perel[table][key or #tags.perel[table]+1] = tag
  ghost.tags = tags
end

---Sets the specified key to the tag
---@param ghost LuaEntity
---@param key string
---@param tag any
perel.set_tag = function(ghost, key, tag)
  if not ghost or not ghost.valid or ghost.type ~= "entity-ghost" then return end
  local tags = ghost.tags or {}
  tags.perel = tags.perel or {}
  tags.perel[key] = tag
  ghost.tags = tags
end

---Gets a tag from the entity
---@param ghost LuaEntity
---@param key string
---@return any tag nil if not ghost or no tags
perel.get_tag = function(ghost, key)
  return ghost and ghost.valid and ghost.type == "entity-ghost" and ghost.tags and ghost.tags.perel and ghost.tags.perel[key] or nil
end

return perel
