-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@diagnostic disable-next-line: assign-type-mismatch
---@class (partial) PEREL.storage
storage = storage or {}

assert(prototypes.item.coin, "ERROR: item 'coin' not found!")

---@class (partial) PEREL
---@field events PEREL.events
---@field enabled_events PEREL.enabled_events
---@field event_categories PEREL.event_categories
---@field handlers {[string]: fun(event: EventData): boolean?}
perel = perel or {}

---@class PEREL.events
---@field on_built defines.events[]
---@field on_destroyed defines.events[]

---@class PEREL.enabled_events
---@field pre_circuit_wire_added boolean
---@field circuit_wire_added boolean
---@field pre_circuit_wire_removed boolean
---@field circuit_wire_removed boolean
---@field pre_circuit_network_created boolean
---@field circuit_network_created boolean
---@field pre_circuit_network_destroyed boolean
---@field circuit_network_destroyed boolean
---@field pre_circuit_network_merged boolean
---@field circuit_network_merged boolean
---@field pre_circuit_network_split boolean
---@field circuit_network_split boolean
---@field pre_electric_wire_added boolean
---@field electric_wire_added boolean
---@field pre_electric_wire_removed boolean
---@field electric_wire_removed boolean
---@field pre_electric_network_created boolean
---@field electric_network_created boolean
---@field pre_electric_network_destroyed boolean
---@field electric_network_destroyed boolean
---@field pre_electric_network_merged boolean
---@field electric_network_merged boolean
---@field pre_electric_network_split boolean
---@field electric_network_split boolean

---@class PEREL.event_categories
---@field circuit_wire boolean
---@field circuit_network boolean
---@field electric_wire boolean
---@field electric_network boolean

---@diagnostic disable-next-line: missing-fields
perel.events = {}
perel.events.on_built = {
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive
}
perel.events.on_destroyed = {
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_space_platform_mined_entity,
  defines.events.script_raised_destroy,
  defines.events.on_entity_died
}

---@diagnostic disable-next-line: missing-fields
perel.event_handlers = {}

---@diagnostic disable-next-line: missing-fields
perel.enabled_events = {}

-- index over all startup settings and note which events should be enabled
-- probably a bad idea but oh well
local all_events = settings.startup["perel-enable-all-events"].value
for name, setting in pairs(settings.startup) do
  if name:sub(1,6) == "perel_" and (all_events or setting.value) then
    ---@diagnostic disable-next-line: inject-field
    perel.enabled_events[name:sub(7)] = true
  end
end

-- easy way to check if entire sections of runtime code are required
---@diagnostic disable-next-line: missing-fields
perel.event_categories = {}
perel.event_categories.circuit_wire =
  perel.enabled_events.pre_circuit_wire_added or
  perel.enabled_events.circuit_wire_added or
  perel.enabled_events.pre_circuit_wire_removed or
  perel.enabled_events.circuit_wire_removed
perel.event_categories.circuit_network =
  perel.enabled_events.pre_circuit_network_created or
  perel.enabled_events.circuit_network_created or
  perel.enabled_events.pre_circuit_network_destroyed or
  perel.enabled_events.circuit_network_destroyed or
  perel.enabled_events.pre_circuit_network_merged or
  perel.enabled_events.circuit_network_merged or
  perel.enabled_events.pre_circuit_network_split or
  perel.enabled_events.circuit_network_split
perel.event_categories.electric_wire =
  perel.enabled_events.pre_electric_wire_added or
  perel.enabled_events.electric_wire_added or
  perel.enabled_events.pre_electric_wire_removed or
  perel.enabled_events.electric_wire_removed
perel.event_categories.electric_network =
  perel.enabled_events.pre_electric_network_created or
  perel.enabled_events.electric_network_created or
  perel.enabled_events.pre_electric_network_destroyed or
  perel.enabled_events.electric_network_destroyed or
  perel.enabled_events.pre_electric_network_merged or
  perel.enabled_events.electric_network_merged or
  perel.enabled_events.pre_electric_network_split or
  perel.enabled_events.electric_network_split

-- per-event special handlers ran before the event is sent
perel.handlers = {}

---@class (partial) PEREL
---@field on_event fun(event: defines.events|defines.events[]|defines.events[][]|string, handler: fun(event: EventData))
---@field on_init fun(handler: fun(event: ConfigurationChangedData?))
---@field tock fun(): uint64, uint64, defines.target_type
perel = perel or {}

-- save event for later when registered
perel.on_event = function(event, handler)
  if type(event) == "table" then
    for _, event_id in pairs(event) do
      perel.on_event(event_id, handler)
    end
  elseif event then
    if not perel.event_handlers[event] then
      perel.event_handlers[event] = {}
      script.on_event(event, function(e)
        for _, handle in pairs(perel.event_handlers[event]) do handle(e) end
      end)
    end
    perel.event_handlers[event][#perel.event_handlers[event]+1] = handler
  end
end

-- same for init and config changed, merged for ease of use
perel.event_handlers.on_init = {}
perel.on_init = function(handler)
  perel.event_handlers.on_init[#perel.event_handlers.on_init+1] = handler
end
script.on_init(function(e)
  for _, handler in pairs(perel.event_handlers.on_init) do handler(e) end
end)
script.on_configuration_changed(function(e)
  for _, handler in pairs(perel.event_handlers.on_init) do handler(e) end
end)

-- register one of each event to call subevents from
-- expensive, but it works. might need to change later

perel.tock = function()
  storage.grandfather.insert{name = "coin", health = 0.5}
  ---@diagnostic disable-next-line: param-type-mismatch
  local num, num2, type = script.register_on_object_destroyed(storage.grandfather[1].item)
  storage.grandfather.clear()
  return num, num2, type
end

perel.remove_invalid = function(table)
  for index, value in pairs(table) do
    if type(value) == "userdata" and value.valid == false then
      table[index] = nil
    elseif type(value) == "table" then -- table of data, check individually
      perel.remove_invalid(value)
    end
  end
end

-- immediately fires event, if enabled
---@param event_name string
---@param event_data EventData
perel.fire_event = function(event_name, event_data)
  if not event_name or not event_data then return end
  if not perel.enabled_events[event_name] then return end
  event_data.name = defines.events["on_" .. event_name]
  script.raise_event(event_data.name, event_data)
end

-- fires on_pre_ events and delays full event triggering, if enabled
---@param event_name string
---@param event_data EventData
---@param skip_pre_fire_event? boolean
perel.delayed_fire_event = function(event_name, event_data, skip_pre_fire_event)
  if not event_name or not event_data then return end
  if perel.enabled_events[event_name] then
    storage.event_deathrattles[perel.tock()] = {
      event_name = event_name,
      event_data = event_data
    }
  end

  if not skip_pre_fire_event and perel.enabled_events["pre_" .. event_name] then
    event_data.name = defines.events["on_pre_" .. event_name]
    script.raise_event(event_data.name, event_data)
  end
end

-- generic post event subtick handler via deathrattles
---@param event EventData.on_object_destroyed
perel.on_event(defines.events.on_object_destroyed, function (event)
  local metadata = storage.event_deathrattles[event.registration_number]
  storage.event_deathrattles[event.registration_number] = nil

  if not metadata or not metadata.event_name or not metadata.event_data then return end

  local event_name = metadata.event_name
  local event_data = metadata.event_data
  -- sanitize
  perel.remove_invalid(event_data)
  -- if special handling for this event, run it
  if perel.handlers[event_name] and perel.handlers[event_name](event_data) or not perel.handlers[event_name] then
    perel.fire_event(event_name, event_data)
  end
end)

---Appends the tag to the specified table
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