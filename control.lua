require "__perel__.handlers"

perel.on_init(function()
  storage = {
    grandfather = storage.grandfather or game.create_inventory(1),
    event_deathrattles = storage.event_deathrattles or {},
    circuit_network_last_added = storage.circuit_network_last_added or {},
    wire_connection_target_cache = { ["entity-ghost"] = false } -- dynamically generated, cleared when mods change/update
  }
end)

require "__perel__.scripts.circuit_network"

local function remove_invalid(tables)
  for index, value in pairs(tables) do
    if type(value) == "userdata" and value.valid == false then
      tables[index] = nil
    elseif type(value) == "table" then -- table of data, check individually
      remove_invalid(value)
    end
  end
end

-- generic post event subtick handler via deathrattles
perel.on_event(defines.events.on_object_destroyed, function (event)
  local metadata = storage.event_deathrattles[event.registration_number]

  if not metadata or not metadata.event_name or not metadata.event_data then return end
  local event_name = metadata.event_name
  local event_data = metadata.event_data or {}

  -- basic validation
  remove_invalid(event_data)

  if perel.enabled_events[event_name] then
    event_data.name = defines.events["on_" .. event_name]
    script.raise_event(event_data.name, event_data)
  end

  -- clear data on exit
  storage.event_deathrattles[event.registration_number] = nil
end)