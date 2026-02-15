if not perel.event_categories.circuit_wire and not perel.event_categories.circuit_network then return end

local function valid_wire_target(entity)
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
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if type ~= "wall" then return false end
  for _, direction in pairs{
    "north",
    "east",
    "south",
    "west"
  } do
    local neighbour = entity.neighbours[direction]
    local type = neighbour and (neighbour.type == "entity-ghost" and neighbour.ghost_type or neighbour.type) or ""
    if type == "gate" then return false end
  end
  return true
end

---@param wire_connector_id defines.wire_connector_id
---@return defines.wire_type
local function type_from_connector(wire_connector_id)
  return (wire_connector_id == defines.wire_connector_id.circuit_green or
    wire_connector_id == defines.wire_connector_id.combinator_input_green or
    wire_connector_id == defines.wire_connector_id.combinator_output_green) and
    defines.wire_type.green or defines.wire_type.red
end

---@param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity|EventData.script_raised_built|EventData.script_raised_revive|EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_space_platform_mined_entity|EventData.script_raised_destroy|EventData.on_entity_died
perel.on_event({perel.events.on_built, perel.events.on_destroyed}, function (event)
  local source_entity = event.entity
  -- make sure it supports circuit wires and is a valid wall, ignore ghosts
  if not valid_wire_target(source_entity.name) or invalid_wall(source_entity) then return end
  -- for each wire node option
  for wire_connector_id, wire_connector in pairs(source_entity.get_wire_connectors() or {}) do
    if wire_connector and wire_connector_id < 5 then -- ignore copper wires
      local networks = perel.event_categories.electric_network and {} or nil
      local solo_event_data = {} -- for each on_circuit_wire_added/removed
      local combined_event_data = { -- on_circuit_network_created/destroyed, on_circuit_network_merged/split
        player_index = event.player_index or nil,
        tick = game.tick,
        source = source_entity,
        source_connector_id = wire_connector_id,
        destinations = {},
        wire_type = type_from_connector(wire_connector_id),
      }
      -- stash connections
      local connections = wire_connector.real_connections
      -- temp disconnect
      wire_connector.disconnect_all()
      -- for each connection
      for _, wire_connection in pairs(connections) do
        -- ignore radar and script connections
        if wire_connection.origin == defines.wire_origin.player then
          -- generate event data
          solo_event_data[#solo_event_data+1] = {
            player_index = event.player_index or nil,
            tick = game.tick,
            source = source_entity,
            source_connector_id = wire_connector_id,
            destination = wire_connection.target.owner,
            destination_connector_id = wire_connection.target.wire_connector_id,
            wire_type = wire_connection.wire_type,
          }
          combined_event_data.destinations[#combined_event_data.destinations+1] = {
            entity = wire_connection.target.owner,
            connector_id = wire_connection.target.wire_connector_id
          }
          -- checking may not be required
          if networks and table_size(networks) < 2 then
            networks[wire_connection.target.network_id] = true
          end
        end
      end

      -- reconnect
      for _, wire_connection in pairs(connections) do
        wire_connector.connect_to(wire_connection.target, false, wire_connection.origin)
      end

      local event_names = (event.name == 6 or event.name == 18 or event.name == 78 or event.name == 92 or event.name == 94) and {
        "circuit_wire_added",
        "circuit_network_created",
        "circuit_network_merged"
      } or {
        "circuit_wire_removed",
        "circuit_network_destroyed",
        "circuit_network_split"
      }

      -- raise events, only fire combined event if destinations exist
      combined_event_data = #combined_event_data.destinations > 0 and combined_event_data or nil
      perel.delayed_fire_event(table_size(networks) == 0 and event_names[2] or table_size(networks) == 2 and event_names[3] or nil, combined_event_data)
      for _, event_data in pairs(solo_event_data) do
        perel.delayed_fire_event(event_names[1], event_data)
      end
    end
  end
end)

-- special handling for when a ghost pole is destroyed and connects adjacent unconnected networks
---@param event EventData.on_pre_ghost_deconstructed
perel.on_event(defines.events.on_pre_ghost_deconstructed, function (event)
  local entity = event.ghost
  if entity.ghost_type ~= "electric-pole" then return end
end)

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
  if (entity.type == "entity-ghost" and entity.ghost_type or entity.type) ~= "electric-pole" or
    not valid_wire_target(entity.name == "entity-ghost" and entity.ghost_name or entity.name) then return end

  for wire_connector_id, wire_connector in pairs(entity.get_wire_connectors()) do
    if wire_connector_id < 5 then -- ignore copper wires
      -- cache connections
      local connections = wire_connector.connections

      -- disconnect from all
      wire_connector.disconnect_all()

      -- check networks, cache changes
      local networks = perel.event_categories.circuit_network and {} or nil
      local solo_event_data = {} -- for each on_circuit_wire_removed
      local combined_event_data = { -- on_circuit_network_destroyed, on_circuit_network_split
        player_index = event.player_index or nil,
        tick = game.tick,
        source = entity,
        source_connector_id = defines.wire_connector_id.pole_copper,
        destinations = {},
        wire_type = type_from_connector(wire_connector_id),
      }

      for _, wire_connection in pairs(connections) do
        -- ignore radar and script connections
        if wire_connection.origin == defines.wire_origin.player then
          -- generate event data
          solo_event_data[#solo_event_data+1] = {
            player_index = event.player_index or nil,
            tick = game.tick,
            source = entity,
            source_connector_id = defines.wire_connector_id.pole_copper,
            destination = wire_connection.target.owner,
            destination_connector_id = wire_connection.target.wire_connector_id,
            wire_type = wire_connection.wire_type,
          }
          if wire_connection.target.owner.type ~= "entity-ghost" then
            combined_event_data.destinations[#combined_event_data.destinations+1] = {
              entity = wire_connection.target.owner,
              connector_id = wire_connection.target.wire_connector_id ---------------------- TODO: function (possibly generic) for counting networks and getting data from destinations, i do this too many times
            }
          end
        end
      end

      -- reconnect
      for _, wire_connection in pairs(connections) do
        wire_connector.connect_to(wire_connection.target, false, wire_connection.origin)
      end

      -- raise events, only fire 'split' event if destinations found and this entity is not a ghost
      combined_event_data = entity.type ~= "entity-ghost" and #combined_event_data.destinations > 0 and combined_event_data or nil
      perel.delayed_fire_event(table_size(networks) == 0 and "circuit_network_destroyed" or table_size(networks) == 2 and "circuit_network_split" or nil, combined_event_data)
      for _, event_data in pairs(solo_event_data) do
        perel.delayed_fire_event("circuit_wire_removed", event_data)
      end
    end
  end
end)

-- no need to track wire movements if no events will be fired
if not perel.event_categories.circuit_wire then return end

-- remove monitor, if no longer holding a wire
---@param event EventData.on_player_cursor_stack_changed
perel.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.get_player(event.player_index)
  local item = player.cursor_stack
  if player.is_cursor_empty() or not item or not item.valid_for_read or (item.name ~= "green-wire" and item.name ~= "red-wire") then
    storage.circuit_network_last_added[event.player_index] = nil
  end
end)

-- you can't pipette a wire so just nil out regardless
---@param event EventData.CustomInputEvent
perel.on_event("perel-pipette", function (event)
  storage.circuit_network_last_added[event.player_index] = nil
end)

---@param event EventData.CustomInputEvent
perel.on_event("perel-build", function (event)
  local player = game.get_player(event.player_index)

  -- only check for new network connections if the player is holding a wire and hovering over an entity
  if player.is_cursor_empty() or not player.cursor_stack or not player.cursor_stack.valid_for_read or (player.cursor_stack.name ~= "green-wire" and player.cursor_stack.name ~= "red-wire") or not player.selected or not player.selected.valid then return end

  local wire_destination = player.selected
  local destination_prototype = wire_destination.name == "entity-ghost" and wire_destination.ghost_prototype or wire_destination.prototype
  -- make sure it supports circuit wires and is a valid wall
  if not valid_wire_target(destination_prototype.name) or invalid_wall(wire_destination) then return end

  local wire_source_data = storage.circuit_network_last_added[event.player_index]

  -- if the first entity selected, save it and return early
  if not wire_source_data then
    -- save data in variables for calculating combinator input/output selection
    local cursor_pos = event.cursor_position
    local destination_pos = wire_destination.position
    local destination_dir = wire_destination.direction

    storage.circuit_network_last_added[event.player_index] = {
      entity = wire_destination,
      connector_id = defines.wire_connector_id[(
        destination_prototype.active_energy_usage and destination_prototype.type ~= "rocket-silo" and (
          "combinator_" .. (
            ( -- check that we are selecting the input side of the combinator
              destination_dir == 00 and cursor_pos.y > destination_pos.y or
              destination_dir == 04 and cursor_pos.x < destination_pos.x or
              destination_dir == 08 and cursor_pos.y < destination_pos.y or
              destination_dir == 12 and cursor_pos.x > destination_pos.x
            ) and "input_" or "output_"
          )
        ) or "circuit_"
      ) .. player.cursor_stack.name:sub(1,-6)]
    }
    return
  end

  local wire_source = wire_source_data.entity

  -- if last entity added to wire can reach (and not same entity), then run network creation logic
  if wire_destination.unit_number ~= wire_source.unit_number and wire_destination.can_wires_reach(wire_source) then

    -- note that the wire has not actually been added yet, so this is the pre-event state

    -- save data in variables for calculating combinator input/output selection
    local cursor_pos = event.cursor_position
    local destination_pos = wire_destination.position
    local destination_dir = wire_destination.direction

    -- precalculate event data for later use and firing
    local solo_event_data = {
      player_index = event.player_index,
      tick = game.tick,
      source = wire_source,
      source_connector_id = wire_source_data.connector_id,
      destination = wire_destination,
      destination_connector_id = defines.wire_connector_id[
        (
          destination_prototype.active_energy_usage and destination_prototype.type ~= "rocket-silo" and (
            "combinator_" .. (
              ( -- check that we are selecting the input side of the combinator
                destination_dir == 00 and cursor_pos.y > destination_pos.y or
                destination_dir == 04 and cursor_pos.x < destination_pos.x or
                destination_dir == 08 and cursor_pos.y < destination_pos.y or
                destination_dir == 12 and cursor_pos.x > destination_pos.x
              ) and "input_" or "output_"
            )
          ) or "circuit_"
        ) .. player.cursor_stack.name:sub(1,-6)
      ],
      wire_type = type_from_connector(wire_source_data.connector_id),
    }
    local combined_event_data = {
      player_index = event.player_index,
      tick = game.tick,
      source = wire_source,
      source_connector_id = wire_source_data.connector_id,
      destinations = {
        {
          entity = wire_destination,
          connector_id = solo_event_data.destination_connector_id -- aint gonna do that shit again
        }
      },
      wire_type = type_from_connector(wire_source_data.connector_id),
    }

    local source_connector = wire_source.get_wire_connector(solo_event_data.source_connector_id, true)
    local destination_connector = wire_destination.get_wire_connector(solo_event_data.destination_connector_id, true)

    local solo_event, combined_event = source_connector.is_connected_to(destination_connector) and "circuit_wire_removed" or "circuit_wire_added"

    if perel.event_categories.circuit_network then
      -- temporarily disconnect
      if solo_event == "circuit_wire_removed" then
        source_connector.disconnect_from(destination_connector)
      end
      local s_id = source_connector.network_id
      local d_id = destination_connector.network_id

      if s_id == d_id and s_id == 0 and wire_source.type ~= "entity-ghost" and wire_destination.type ~= "entity-ghost" then
        -- both zero (nonexistant) networks so network created/destroyed
        combined_event = solo_event == "circuit_wire_added" and "circuit_network_created" or "circuit_network_destroyed"
      elseif s_id ~= d_id and s_id ~= 0 and d_id ~= 0 then
        -- both nonzero (existing) networks that are different, so network merged/split
        combined_event = solo_event == "circuit_wire_added" and "circuit_network_merged" or "circuit_network_split"
      end

      -- reconnect entities
      if solo_event == "circuit_wire_removed" then
        source_connector.connect_to(destination_connector)
      end
    end

    -- raise events, only fire combined event if destinations exist
    perel.delayed_fire_event(combined_event, combined_event_data)
    perel.delayed_fire_event(solo_event, solo_event_data)

    storage.circuit_network_last_added[event.player_index] = solo_event == "circuit_wire_added" and {
      entity = wire_destination,
      connector_id = solo_event_data.destination_connector_id
    } or nil
  end
end)

perel.on_init(function()
  storage.circuit_wire_connection_target_cache = { ["entity-ghost"] = false } -- dynamically generated, cleared when mods change/update
  storage.circuit_network_last_added = storage.circuit_network_last_added or {}
end)