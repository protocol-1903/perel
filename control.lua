script.on_init(function (event)
  storage = {
    circuit_network_last_added = {},
    deathrattles = {}
  }
end)

script.on_configuration_changed(function (event)
  storage = {
    circuit_network_last_added = storage.circuit_network_last_added or {},
    deathrattles = storage.deathrattles or {}
  }
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.get_player(event.player_index)
  local item = player.cursor_stack
  if player.is_cursor_empty() or not item or not item.valid_for_read or (item.name ~= "green-wire" and item.name ~= "red-wire") then
    -- remove circuit_network_monitor
    storage.circuit_network_last_added[event.player_index] = nil
  end
end)

script.on_event("perel-pipette", function (event)
  storage.circuit_network_last_added[event.player_index] = nil
end)

script.on_event("perel-build", function (event)

  local player = game.get_player(event.player_index)
  
  -- only check for new network connections if the player is holding a wire and hovering over an entity
  if player.is_cursor_empty() or not player.cursor_stack or not player.cursor_stack.valid_for_read or (player.cursor_stack.name ~= "green-wire" and player.cursor_stack.name ~= "red-wire") or not player.selected then return end

  local wire_destination = player.selected

  local destination_prototype = wire_destination.name == "entity-ghost" and wire_destination.ghost_prototype or wire_destination.prototype
  
  -- ensure the entity (if exist) supports the circuit network
  if destination_prototype.get_max_circuit_wire_distance(wire_destination.quality) ~= 0 then
    
    local wire_source_data = storage.circuit_network_last_added[event.player_index]
    
    -- if the first entity selected, save it and return early
    if not storage.circuit_network_last_added[event.player_index] then

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

    log(wire_destination)
    log(wire_source)

    -- if last entity added to wire can reach (and not same entity), then run network creation logic
    if wire_destination.unit_number ~= wire_source.unit_number and wire_destination.can_wires_reach(wire_source) then

      -- note that the wire has not actually been added yet, so this is the pre-event state

      -- save data in variables for calculating combinator input/output selection
      local cursor_pos = event.cursor_position
      local destination_pos = wire_destination.position
      local destination_dir = wire_destination.direction

      -- precalculate event data for later use and firing
      local event_data, events = {
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
        wire_type = defines.wire_type[player.cursor_stack.name:sub(1,-6)],
      }


      local source_connector = wire_source.get_wire_connector(event_data.source_connector_id, true)
      local destination_connector = wire_destination.get_wire_connector(event_data.destination_connector_id, true)

      -- check if a wire is being added or removed
      if wire_source.get_wire_connector(event_data.source_connector_id, true).is_connected_to(wire_destination.get_wire_connector(event_data.destination_connector_id, true)) then
        -- wire is being removed
        events = {"on_circuit_wire_removed"}
      else
        -- wire is being added
        events = {"on_circuit_wire_added"}
      end

      if events[1] == "on_circuit_wire_added" and source_connector.network_id == destination_connector.network_id and source_connector.network_id == 0 and wire_source.type ~= "entity-ghost" and wire_destination.type ~= "entity-ghost" then
        -- wire is being added between two nonexistant networks
        events[#events+1] = "on_circuit_network_created"
      elseif events[1] == "on_circuit_wire_added" and source_connector.network_id ~= destination_connector.network_id and source_connector.network_id ~= 0 and destination_connector.network_id ~= 0 then
        -- wire is connecting two disconnected networks
        events[#events+1] = "on_circuit_network_merged"
      end

      -- this logic triggers a delayed subtick event so that the circuit network events are triggered after the wire is added
      local trigger = game.surfaces[1].create_entity{name = "perel-trigger-entity", position = {0,0}}
      storage.deathrattles[script.register_on_object_destroyed(trigger)] = {
        events = events,
        event_data = event_data
      }
      trigger.destroy()
    end
  end
end)

script.on_event(defines.events.on_object_destroyed, function (event)

  local metadata = storage.deathrattles[event.registration_number]
  
  if not metadata then return end

  local events = metadata.events
  local event_data = metadata.event_data

  if events and event_data then

      local source_connector = event_data.source.get_wire_connector(event_data.source_connector_id, true)
      local destination_connector = event_data.destination.get_wire_connector(event_data.destination_connector_id, true)

      if events[1] == "on_circuit_wire_removed" and source_connector.network_id ~= destination_connector.network_id and source_connector.network_id ~= 0 and destination_connector.network_id ~= 0 then
        -- circuit network is being split
        events[#events+1] = "on_circuit_network_split"
      elseif events[1] == "on_circuit_wire_removed" and source_connector.network_id == destination_connector.network_id and source_connector.network_id == 0 and event_data.source.type == "entity-ghost" and event_data.destination.type == "entity-ghost" then
        -- wire is connecting two disconnected networks
        events[#events+1] = "on_circuit_network_destroyed"
      end

      for i = 1, #events do
        event_data.name = events[i]
        script.raise_event(defines.events[events[i]], event_data)
      end
  end
end)

for _, eventy in pairs{
  "on_circuit_wire_added",
  "on_circuit_wire_removed",
  "on_circuit_network_created",
  "on_circuit_network_destroyed",
  "on_circuit_network_merged",
  "on_circuit_network_split",
} do
  script.on_event(defines.events[eventy], function (event)
    game.print(eventy, {skip = defines.print_skip.never})
  end)
end