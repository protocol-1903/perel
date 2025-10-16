assert(prototypes.item.coin, "ERROR: item 'coin' not found!")

script.on_init(function (event)
  storage = {
    circuit_network_last_added = {},
    deathrattles = {},
    grandfather = game.create_inventory(1)
  }
end)

script.on_configuration_changed(function (event)
  storage = {
    circuit_network_last_added = storage.circuit_network_last_added or {},
    deathrattles = storage.deathrattles or {},
    grandfather = storage.grandfather or game.create_inventory(1)
  }
end)

local function tock()
  storage.grandfather.insert{name = "coin", health = 0.5}
  local num = script.register_on_object_destroyed(storage.grandfather[1].item)
  storage.grandfather.clear()
  return num
end

local wire_connection_whitelist = {
  -- TODO fill this out so i can use it in the events instead of an API call :P
  -- also note, skip splitters until 2.0.67
}

local function nodes(type)
  return (type == "decider-combinator" or type == "arithmetic-combinator" or type == "selector-combinator") and {
    defines.wire_connector_id.combinator_input_red,
    defines.wire_connector_id.combinator_input_green,
    defines.wire_connector_id.combinator_output_red,
    defines.wire_connector_id.combinator_output_green
  } or {
    defines.wire_connector_id.circuit_red,
    defines.wire_connector_id.circuit_green
  }
end

script.on_event({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive
}, function (event)
  local source_entity = event.entity
  -- ignore ghosts and make sure it supports circuit wires
  if source_entity.type ~= "entity-ghost" and source_entity.prototype.get_max_circuit_wire_distance() ~= 0 then
    -- for each wire node option
    for _, wire_connector_id in pairs(nodes(source_entity.type)) do
      local events = {}
      local existing_connections = 0
      -- for each connection
      for i, wire_connection in pairs(source_entity.get_wire_connector(wire_connector_id, true).real_connections) do
        -- ignore radar and script connections
        if wire_connection.origin ~= defines.wire_origin.script and wire_connection.origin ~= defines.wire_origin.radars then
          -- generate event data
          events[#events+1] = {
            player_index = event.player_index or nil,
            tick = game.tick,
            source = source_entity,
            source_connector_id = wire_connector_id,
            destination = wire_connection.target.owner,
            destination_connector_id = wire_connection.target.wire_connector_id,
            wire_type = wire_connection.wire_type,
          }

          -- check for existing connections to other entities to determine if network_created or network_merged events should be fired
          for _, sub_wire_connection in pairs(wire_connection.target.real_connections) do
            -- only count entities that are not script/radar connections and not the entity that caused this event, also skip if we already know of 2 other networks so we'd fire merged anyway
            if existing_connections ~= 2 and sub_wire_connection.origin ~= defines.wire_origin.script and sub_wire_connection.origin ~= defines.wire_origin.radars and sub_wire_connection.target.owner.unit_number ~= source_entity.unit_number then
              existing_connections = existing_connections + 1
            end
          end
        end
      end

      -- raise events
      for _, event_name in pairs({
        "circuit_wire_added",
        -- check how many existing connections were found to determine if merged or created should be used
        existing_connections == 0 and "circuit_network_created" or nil, -- no other networks detected, creating network
        existing_connections == 2 and "circuit_network_merged" or nil -- 2+ networks detected, merging networks
      }) do
        for _, event_data in pairs(events) do
          event_data.name = defines.events["on_" .. event_name]
          script.raise_event(event_data.name, event_data)
        end
      end
    end
  end
end)

script.on_event({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_space_platform_mined_entity,
  defines.events.script_raised_destroy,
  defines.events.on_entity_died
}, function (event)
  local source_entity = event.entity
  -- ignore ghosts and make sure it supports circuit wires
  if source_entity.type ~= "entity-ghost" and source_entity.prototype.get_max_circuit_wire_distance() ~= 0 then
    -- for each wire node option
    for _, wire_connector_id in pairs(nodes(source_entity.type)) do
      local events = {}
      local existing_connections = 0
      -- for each connection
      for i, wire_connection in pairs(source_entity.get_wire_connector(wire_connector_id, true).real_connections) do
        -- ignore radar and script connections
        if wire_connection.origin ~= defines.wire_origin.script and wire_connection.origin ~= defines.wire_origin.radars then
          -- generate event data
          events[#events+1] = {
            player_index = event.player_index or nil,
            tick = game.tick,
            source_connector_id = wire_connector_id,
            destination = wire_connection.target.owner,
            destination_connector_id = wire_connection.target.wire_connector_id,
            wire_type = wire_connection.wire_type,
          }
          
          -- checking may not be required
          if existing_connections ~= 2 then
            -- check for existing connections to other entities to determine if network_created or network_merged events should be fired
            for _, sub_wire_connection in pairs(wire_connection.target.real_connections) do
              -- only count entities that are not script/radar connections and not the entity that caused this event, also skip if we already know of 2 other networks so we'd fire merged anyway
              if sub_wire_connection.origin ~= defines.wire_origin.script and sub_wire_connection.origin ~= defines.wire_origin.radars and sub_wire_connection.target.owner.unit_number ~= source_entity.unit_number then
                existing_connections = existing_connections + 1
                break
              end
            end
          end
        end
      end

      local event_names = {
        "circuit_wire_removed",
        -- check how many existing connections were found to determine if merged or created should be used
        existing_connections == 0 and "circuit_network_destroyed" or -- no other networks detected, destroying network
        existing_connections == 2 and "circuit_network_split" or nil -- 2+ networks detected, splitting networks
      }

      for _, event_data in pairs(events) do
        storage.deathrattles[tock()] = {
          events = event_names,
          event_data = event_data
        }
      end

      -- raise events
      for _, event_name in pairs(event_names) do
        for _, event_data in pairs(events) do
          event_data.name = defines.events["on_pre_" .. event_name]
          script.raise_event(event_data.name, event_data)
        end
      end
    end
  end
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
  if destination_prototype.get_max_circuit_wire_distance() ~= 0 then
    
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
        events = {"circuit_wire_removed"}
      else
        -- wire is being added
        events = {"circuit_wire_added"}
      end

      if events[1] == "circuit_wire_added" and source_connector.network_id == destination_connector.network_id and source_connector.network_id == 0 and wire_source.type ~= "entity-ghost" and wire_destination.type ~= "entity-ghost" then
        -- wire is being added between two nonexistant networks
        events[#events+1] = "circuit_network_created"
      elseif events[1] == "circuit_wire_added" and source_connector.network_id ~= destination_connector.network_id and source_connector.network_id ~= 0 and destination_connector.network_id ~= 0 then
        -- wire is connecting two disconnected networks
        events[#events+1] = "circuit_network_merged"
      elseif events[1] == "circuit_wire_removed" then
        -- disconnect entities
        source_connector.disconnect_from(destination_connector)

        -- if both have distinct nonconjoined networks
        if source_connector.network_id ~= destination_connector.network_id and source_connector.network_id ~= 0 and destination_connector.network_id ~= 0 then
          -- both nonzero (existing) networks that are different, so network split
          events[2] = "circuit_network_split"
        elseif source_connector.network_id == destination_connector.network_id and source_connector.network_id == 0 and wire_source.type ~= "entity-ghost" and wire_destination.type ~= "entity-ghost" then
          -- both zero (nonexistant) networks so network destroyed
          events[2] = "circuit_network_destroyed"
        end
        
        -- reconnect entities
        source_connector.connect_to(destination_connector)
      end

      for _, event_name in pairs(events) do
        event_data.name = defines.events["on_pre_" .. event_name]
        script.raise_event(event_data.name, event_data)
      end

      -- trigger a delayed event
      storage.deathrattles[tock()] = {
        events = events,
        event_data = event_data
      }
      
      storage.circuit_network_last_added[event.player_index] = events[1] == "circuit_wire_added" and {
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
      } or nil
    end
  end
end)

script.on_event(defines.events.on_object_destroyed, function (event)

  local metadata = storage.deathrattles[event.registration_number]
  
  if not metadata then return end

  local events = metadata.events or {}
  local event_data = metadata.event_data or {}

  -- basic validation
  event_data.source = event_data.source.valid and event_data.source or nil
  event_data.destination = event_data.destination.valid and event_data.destination or nil

  for _, event_name in pairs(events) do
    event_data.name = defines.events["on_" .. event_name]
    script.raise_event(event_data.name, event_data)
  end

  -- clear data on exit
  storage.deathrattles[event.registration_number] = nil
end)

-- TODO
-- fix place ghost merging networks instead of extending existing

-- testing functionality
--[[

script.on_event(defines.events.on_pre_circuit_wire_added, function() game.print("on_pre_circuit_wire_added", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_wire_added, function() game.print("on_circuit_wire_added", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_pre_circuit_wire_removed, function() game.print("on_pre_circuit_wire_removed", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_wire_removed, function() game.print("on_circuit_wire_removed", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_pre_circuit_network_created, function() game.print("on_pre_circuit_network_created", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_network_created, function() game.print("on_circuit_network_created", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_pre_circuit_network_destroyed, function() game.print("on_pre_circuit_network_destroyed", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_network_destroyed, function() game.print("on_circuit_network_destroyed", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_pre_circuit_network_merged, function() game.print("on_pre_circuit_network_merged", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_network_merged, function() game.print("on_circuit_network_merged", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_pre_circuit_network_split, function() game.print("on_pre_circuit_network_split", {skip = defines.print_skip.never}) end)
script.on_event(defines.events.on_circuit_network_split, function() game.print("on_circuit_network_split", {skip = defines.print_skip.never}) end)

--]]