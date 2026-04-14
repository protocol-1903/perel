if not perel.event_categories.circuit_wire and
  not perel.event_categories.electric_wire and
  not perel.event_categories.circuit_network and
  not perel.event_categories.electric_network then return end

perel.on_init(function()
  storage.electric_wire_connection_target_cache = { ["entity-ghost"] = false } -- dynamically generated, cleared when mods change/update
  storage.circuit_wire_connection_target_cache = { ["entity-ghost"] = false } -- dynamically generated, cleared when mods change/update
  storage.electric_network_last_added = storage.electric_network_last_added or {}
  storage.circuit_network_last_added = storage.circuit_network_last_added or {}
end)

local function valid_electric_wire_target(entity)
  -- cache if wire connections are supported
  if storage.electric_wire_connection_target_cache[entity] == nil then
    storage.electric_wire_connection_target_cache[entity] = prototypes.entity[entity].get_max_wire_distance() ~= 0
  end
  -- make sure it supports copper wires
  return storage.electric_wire_connection_target_cache[entity]
end

local function valid_circuit_wire_target(entity)
  -- cache if circuit wire connections are supported
  if storage.circuit_wire_connection_target_cache[entity] == nil then
    storage.circuit_wire_connection_target_cache[entity] = prototypes.entity[entity].get_max_circuit_wire_distance() ~= 0
  end
  -- make sure it supports circuit wires
  return storage.circuit_wire_connection_target_cache[entity]
end

---@param entity LuaEntity
---@return boolean
local function invalid_wall(entity)
  if entity.type == "entity-ghost" and entity.ghost_type ~= "wall" or entity.type ~= "wall" then return false end
  for _, direction in pairs{
    "north",
    "east",
    "south",
    "west"
  } do
    local neighbour = entity.neighbours[direction]
    if neighbour and (neighbour.type == "entity-ghost" and neighbour.ghost_type or neighbour.type) == "gate" then return false end
  end
  return true
end

---Gets the wire connector id the player clicked on, based on the position and wire type
---@param entity LuaEntity
---@param cursor_position MapPosition
---@param wire_type defines.wire_type
---@return defines.wire_connector_id
local function get_wire_connector_id(entity, cursor_position, wire_type)
  local prototype = entity.type == "entity-ghost" and entity.ghost_prototype or entity.prototype
  -- save data in variables for calculating combinator/power switch i/o selection
  local position = entity.position
  local direction = entity.direction

  return defines.wire_connector_id[
    wire_type == defines.wire_type.copper and prototype.type == "power-switch" and (cursor_position.x < position.x and "power_switch_left_copper" or "power_switch_right_copper") or
    wire_type == defines.wire_type.copper and prototype.type == "electric-pole" and "pole_copper" or (
      prototype.active_energy_usage and prototype.type ~= "rocket-silo" and (
        "combinator_" .. (
          ( -- check that we are selecting the input side of the combinator
            direction == 00 and cursor_position.y > position.y or
            direction == 04 and cursor_position.x < position.x or
            direction == 08 and cursor_position.y < position.y or
            direction == 12 and cursor_position.x > position.x
          ) and "input_" or "output_"
        )
      ) or "circuit_"
    ) .. (wire_type == defines.wire_type.green and "green" or "red")
  ]
end

local build_events = {
  [defines.events.on_built_entity] = true,
  [defines.events.on_robot_built_entity] = true,
  [defines.events.on_space_platform_built_entity] = true,
  [defines.events.script_raised_built] = true,
  [defines.events.script_raised_revive] = true
}

local wire_types = {
  -- wire_connector_id->wire_type
  [defines.wire_connector_id.circuit_green] = defines.wire_type.green,
  [defines.wire_connector_id.combinator_input_green] = defines.wire_type.green,
  [defines.wire_connector_id.combinator_output_green] = defines.wire_type.green,
  [defines.wire_connector_id.circuit_red] = defines.wire_type.red,
  [defines.wire_connector_id.combinator_input_red] = defines.wire_type.red,
  [defines.wire_connector_id.combinator_output_red] = defines.wire_type.red,
  [defines.wire_connector_id.pole_copper] = defines.wire_type.copper,
  [defines.wire_connector_id.power_switch_left_copper] = defines.wire_type.copper,
  [defines.wire_connector_id.power_switch_right_copper] = defines.wire_type.copper,
  -- item->wire_type
  ["copper-wire"] = defines.wire_type.copper,
  ["green-wire"] = defines.wire_type.green,
  ["red-wire"] = defines.wire_type.red
}

---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity|EventData.script_raised_built|EventData.script_raised_revive|EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_space_platform_mined_entity|EventData.script_raised_destroy|EventData.on_entity_died
perel.on_event({perel.events.on_built, perel.events.on_destroyed}, function (event)
  -- if tagged then update the references (only applies to build events)
  for i in pairs(event.tags and event.tags.perel and event.tags.perel.circuit_network_last_added or {}) do
    storage.circuit_network_last_added[i].entity = event.entity
  end
  for i in pairs(event.tags and event.tags.perel and event.tags.perel.electric_network_last_added or {}) do
    storage.electric_network_last_added[i].entity = event.entity
  end

  local build = build_events[event.name]
  local source_entity = event.entity
  -- ensure wires are supported, ignore ghosts, and events are enabled
  local valid_electric = valid_electric_wire_target(source_entity.name) and
    (perel.event_categories.electric_network or perel.event_categories.electric_wire)
  local valid_circuit = valid_circuit_wire_target(source_entity.name) and not invalid_wall(source_entity) and
    (perel.event_categories.circuit_network or perel.event_categories.circuit_wire)

  local solo_event_data = {} -- for each on_wire_added/removed
  local combined_events = {} -- for each on_network_created/destroyed/merged/split

  -- for each wire node option
  for wire_id, wire_connector in pairs(source_entity.get_wire_connectors() or {}) do
    local wire_type = wire_types[wire_id]
    local electric = wire_type == defines.wire_type.copper
    local type = electric and "electric" or "circuit"
    local wires = electric and perel.event_categories.electric_wire or not electric and perel.event_categories.circuit_wire
    local network = (electric and perel.event_categories.electric_network or not electric and perel.event_categories.circuit_network) and 0 or nil
    if (electric and valid_electric or not electric and valid_circuit) and (wires or network) then
      local combined_event_data = network and {
        tick = event.tick,
        player_index = event.player_index or nil,
        source = source_entity,
        source_connector_id = wire_id,
        destinations = {},
        wire_type = wire_type,
      } or nil
      -- stash connections
      local connections = wire_connector.connections
      local real_connections = wire_connector.real_connections
      -- temporarily disconnect
      wire_connector.disconnect_all()

      for _, wire_connection in pairs(real_connections) do
        -- ignore radar and script added connections
        if wire_connection.origin == defines.wire_origin.player then
          -- generate event data
          if wires then
            solo_event_data[#solo_event_data+1] = {
              name = type .. "_wire_" .. (build and "added" or "removed"),
              tick = event.tick,
              player_index = event.player_index or nil,
              source = source_entity,
              source_connector_id = wire_id,
              destination = wire_connection.target.owner,
              destination_connector_id = wire_connection.target.wire_connector_id,
              wire_type = wire_type,
            }
          end
          if network ~= nil then
            combined_event_data.destinations[#combined_event_data.destinations+1] = {
              entity = wire_connection.target.owner,
              connector_id = wire_connection.target.wire_connector_id
            }
            if network == 0 then
              network = wire_connection.target.network_id
            elseif network and network ~= wire_connection.target.network_id then
              network = false
            end
          end
        end
      end

      -- reconnect
      for _, wire_connection in pairs(connections) do
        wire_connector.connect_to(wire_connection.target, false, wire_connection.origin)
      end

      -- update combined network event, if possible
      if network == false then
        combined_event_data.name = type .. "_network_" .. (build and "merged" or "split")
        combined_events[#combined_events+1] = combined_event_data
      elseif network == 0 then
        combined_event_data.name = type .. "_network_" .. (build and "created" or "destroyed")
        combined_events[#combined_events+1] = combined_event_data
      end
    end
  end

  -- raise events, only fire combined event if destinations exist
  for _, event_data in pairs(combined_events) do
    perel.remove_invalid(event_data.destinations) -- cleanse in case some mod did something
    if #event_data.destinations ~= 0 then
      perel.delayed_fire_event(event_data.name, event_data)
    end
  end
  for _, event_data in pairs(solo_event_data) do
    perel.delayed_fire_event(event_data.name, event_data)
  end
end)

-- special handling for when a ghost pole is destroyed and connects adjacent unconnected networks
-- ---@param event EventData.on_pre_ghost_deconstructed
-- perel.on_event(defines.events.on_pre_ghost_deconstructed, function (event)
--   local entity = event.ghost
--   if entity.ghost_type ~= "electric-pole" then return end
-- end)

-- special handling for when shift clicking a pole to disconnect neighbours
---@param event EventData.CustomInputEvent
perel.on_event("perel-build-shift", function (event)
  local player = game.get_player(event.player_index)

  -- only check if the player is not holding anything or the item does not have a place result and does not have a tile result
  local item = player.cursor_ghost and player.cursor_ghost.name or
    player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.prototype or nil
  if item and (item.place_result or item.place_as_tile_result) then return end

  local entity = player.selected
  if not entity or not entity.valid then return end

  -- make sure it supports circuit wires wires
  if not entity or (entity.type == "entity-ghost" and entity.ghost_type or entity.type) ~= "electric-pole" then return end

  local valid_electric = valid_electric_wire_target(entity.name) and
    (perel.event_categories.electric_network or perel.event_categories.electric_wire)
  local valid_circuit = valid_circuit_wire_target(entity.name) and
    (perel.event_categories.circuit_network or perel.event_categories.circuit_wire)

  local solo_event_data = {} -- for each on_wire_removed
  local combined_events = {} -- for each on_network_destroyed/split

  for i, wire_id in pairs{
    defines.wire_connector_id.pole_copper,
    defines.wire_connector_id.circuit_green,
    defines.wire_connector_id.circuit_red
  } do
    local wire_connector = entity.get_wire_connector(wire_id)
    local electric = i == 1
    local type = electric and "electric" or "circuit"
    local wires = electric and perel.event_categories.electric_wire or not electric and perel.event_categories.circuit_wire
    local network = (electric and perel.event_categories.electric_network or not electric and perel.event_categories.circuit_network) and 0 or nil
    if wire_connector.connection_count ~= 0 and (electric and valid_electric or not electric and valid_circuit) and (wires or network) then
      local combined_event_data = network and {
        player_index = event.player_index or nil,
        tick = event.tick,
        source = entity,
        source_connector_id = defines.wire_connector_id.pole_copper,
        destinations = {},
        wire_type = wire_types[wire_id],
      } or nil
      -- stash connections
      local connections = wire_connector.connections
      local real_connections = wire_connector.real_connections
      -- temporarily disconnect
      wire_connector.disconnect_all()

      for _, wire_connection in pairs(real_connections) do
        -- ignore radar and script added connections
        if wire_connection.origin == defines.wire_origin.player then
          -- generate event data
          solo_event_data[#solo_event_data+1] = {
            name = type .. "_wire_removed",
            tick = event.tick,
            player_index = event.player_index or nil,
            source = entity,
            source_connector_id = wire_id,
            destination = wire_connection.target.owner,
            destination_connector_id = wire_connection.target.wire_connector_id,
            wire_type = wire_connection.wire_type,
          }
          if network ~= nil then
            combined_event_data.destinations[#combined_event_data.destinations+1] = {
              entity = wire_connection.target.owner,
              connector_id = wire_connection.target.wire_connector_id
            }
            if network == 0 then
              network = wire_connection.target.network_id
            elseif network and network ~= wire_connection.target.network_id then
              network = false
            end
          end
        end
      end

      -- reconnect
      for _, wire_connection in pairs(connections) do
        wire_connector.connect_to(wire_connection.target, false, wire_connection.origin)
      end

      -- update combined network event, if possible
      if network == false then
        combined_event_data.name = type .. "_network_split"
        combined_events[#combined_events+1] = combined_event_data
      elseif network == 0 then
        combined_event_data.name = type .. "_network_destroyed"
        combined_events[#combined_events+1] = combined_event_data
      end
    end
    if i == 1 and wire_connector.connection_count ~= 0 then
      break -- copper wires are removed first, so only this event set is fired
    end
  end

  -- raise events, only fire combined event if destinations exist
  for _, event_data in pairs(combined_events) do
    perel.remove_invalid(event_data.destinations) -- cleanse in case some mod did something
    if #event_data.destinations ~= 0 then
      perel.delayed_fire_event(event_data.name, event_data, event_data.name:find("split"))
    end
  end
  for _, event_data in pairs(solo_event_data) do
    perel.delayed_fire_event(event_data.name, event_data)
  end
end)

-- special handling for the edge case that the network is not split when a power pole is deconstructed
---@param event EventData.on_electric_network_split
---@return boolean
perel.handlers.electric_network_split = function (event)
  local network
  for _, destination in pairs(event.destinations) do
    local e = destination.entity
    if e.valid then
      local wire_connector = e.get_wire_connector(destination.connector_id)
      if network and network ~= wire_connector.network_id then
        return true -- networks split, fire event
      end
      network = wire_connector.network_id
    end
  end
  return false -- networks did not split, no entities are valid/all entities are of the same network
end

-- special handling for the edge case that the network is not split when a power pole is deconstructed
---@param event EventData.on_circuit_network_split
---@return boolean
perel.handlers.circuit_network_split = function (event)
  local network
  for _, destination in pairs(event.destinations) do
    local e = destination.entity
    if e.valid then
      local wire_connector = e.get_wire_connector(destination.connector_id)
      if network and network ~= wire_connector.network_id then
        return true -- networks split, fire event
      end
      network = wire_connector.network_id
    end
  end
  return false -- networks did not split, no entities are valid/all entities are of the same network
end

-- no need to track wire movements if no events will be fired
if not perel.event_categories.circuit_wire and not perel.event_categories.electric_wire then return end

-- remove monitor, if no longer holding a wire
---@param event EventData.on_player_cursor_stack_changed
perel.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.get_player(event.player_index)
  local item = player.cursor_stack
  if player.is_cursor_empty() or not item or not item.valid_for_read or (item.name ~= "green-wire" and item.name ~= "red-wire" and item.name ~= "copper-wire") then
    if storage.electric_network_last_added[event.player_index] then
      perel.insert_tag(storage.electric_network_last_added[event.player_index].entity, "electric_network_last_added", nil, event.player_index)
      storage.electric_network_last_added[event.player_index] = nil
    end
    if storage.circuit_network_last_added[event.player_index] then
      perel.insert_tag(storage.circuit_network_last_added[event.player_index].entity, "circuit_network_last_added", nil, event.player_index)
      storage.circuit_network_last_added[event.player_index] = nil
    end
  end
end)

-- you can't pipette a wire so just nil out regardless
---@param event EventData.CustomInputEvent
perel.on_event("perel-pipette", function (event)
  if storage.electric_network_last_added[event.player_index] then
    perel.insert_tag(storage.electric_network_last_added[event.player_index].entity, "electric_network_last_added", nil, event.player_index)
    storage.electric_network_last_added[event.player_index] = nil
  end
  if storage.circuit_network_last_added[event.player_index] then
    perel.insert_tag(storage.circuit_network_last_added[event.player_index].entity, "circuit_network_last_added", nil, event.player_index)
    storage.circuit_network_last_added[event.player_index] = nil
  end
end)

---@param event EventData.CustomInputEvent
perel.on_event("perel-build", function (event)
  local player = game.get_player(event.player_index)

  -- only check for new network connections if the player is holding a wire and hovering over an entity
  if player.is_cursor_empty() or not player.cursor_stack or not player.cursor_stack.valid_for_read or
    (player.cursor_stack.name ~= "green-wire" and player.cursor_stack.name ~= "red-wire" and player.cursor_stack.name ~= "copper-wire") or
    not player.selected or not player.selected.valid then return end

  local wire_destination = player.selected
  local destination_prototype = wire_destination.name == "entity-ghost" and wire_destination.ghost_prototype or wire_destination.prototype
  local electric = player.cursor_stack.name == "copper-wire"
  -- ensure wires are supported, ignore ghosts, and events are enabled
  local valid_electric = valid_electric_wire_target(destination_prototype.name) and
    (perel.event_categories.electric_network or perel.event_categories.electric_wire)
  local valid_circuit = valid_circuit_wire_target(destination_prototype.name) and not invalid_wall(wire_destination) and
    (perel.event_categories.circuit_network or perel.event_categories.circuit_wire)
  if electric and not valid_electric or not electric and not valid_circuit then return end
  local type = electric and "electric" or "circuit"

  local wire_source_data = storage[type .. "_network_last_added"][event.player_index] or {}
  local wire_source = wire_source_data.entity

  -- if the first entity selected (or previously invalid), save it and return early
  if not wire_source or not wire_source.valid then
    perel.insert_tag(wire_destination, type .. "_network_last_added", true, event.player_index)
    storage[---@diagnostic disable-next-line: missing-fields
      type .. "_network_last_added"][event.player_index] = {
        entity = wire_destination,
        connector_id = get_wire_connector_id(wire_destination, event.cursor_position, wire_types[player.cursor_stack.name])
    }
    return
  end

  -- if last entity added to wire can reach (and not same entity), then run network creation logic
  -- note that the wire has not actually been added yet, so this is the pre-event state
  if wire_destination.unit_number ~= wire_source.unit_number and wire_destination.can_wires_reach(wire_source) then
    local wire_type = wire_types[wire_source_data.connector_id]

    local solo_event_data = {
      player_index = event.player_index,
      tick = event.tick,
      source = wire_source,
      source_connector_id = wire_source_data.connector_id,
      destination = wire_destination,
      destination_connector_id = get_wire_connector_id(wire_destination, event.cursor_position, wire_type),
      wire_type = wire_type,
    }
    local combined_event_data = {
      player_index = event.player_index,
      tick = event.tick,
      source = wire_source,
      source_connector_id = wire_source_data.connector_id,
      destinations = {
        {
          entity = wire_source,
          connector_id = solo_event_data.source_connector_id
        },
        {
          entity = wire_destination,
          connector_id = solo_event_data.destination_connector_id -- aint gonna do that shit again
        }
      },
      wire_type = wire_type,
    }

    local source_connector = wire_source.get_wire_connector(solo_event_data.source_connector_id, true)
    local destination_connector = wire_destination.get_wire_connector(solo_event_data.destination_connector_id, true)

    local removed = source_connector.is_connected_to(destination_connector)
    local network = (electric and perel.event_categories.electric_network or not electric and perel.event_categories.circuit_network) and 0 or nil
    local combined

    if network then
      -- temporarily disconnect
      if removed then
        source_connector.disconnect_from(destination_connector)
      end
      local s_id = source_connector.network_id
      local d_id = destination_connector.network_id

      if s_id == d_id and s_id == 0 and wire_source.type ~= "entity-ghost" and wire_destination.type ~= "entity-ghost" then
        -- both zero (nonexistant) networks so network created/destroyed
        combined = removed and "_network_destroyed" or "_network_created"
      elseif s_id ~= d_id and s_id ~= 0 and d_id ~= 0 then
        -- both nonzero (existing) networks that are different, so network merged/split
        combined = removed and "_network_split" or "_network_merged"
      end

      -- reconnect entities
      if removed then
        source_connector.connect_to(destination_connector)
      end

      -- raise events, only fire combined event if destinations exist
      if combined then
        perel.delayed_fire_event(type .. combined, combined_event_data)
      end
    end

    perel.delayed_fire_event(type .. (removed and "_wire_removed" or "_wire_added"), solo_event_data)

    -- remove the tag on the source entity
    perel.insert_tag(wire_source, type .. "_network_last_added", nil, event.player_index)
    if removed then
      storage[type .. "_network_last_added"][event.player_index] = nil
      perel.insert_tag(wire_destination, type .. "_network_last_added", nil, event.player_index)
    else
      storage[---@diagnostic disable-next-line: missing-fields
        type .. "_network_last_added"][event.player_index] = {
          entity = wire_destination,
          connector_id = solo_event_data.destination_connector_id
      } -- add the tag to the destination
      perel.insert_tag(wire_destination, type .. "_network_last_added", true, event.player_index)
    end
  elseif wire_destination.unit_number == wire_source.unit_number then
    -- remove the tag, just clicked the same entity again
      perel.insert_tag(wire_destination, type .. "_network_last_added", nil, event.player_index)
  end
end)