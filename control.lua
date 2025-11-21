perel = require "__perel__.handlers"

perel.on_init(function()
  storage = {
    circuit_network_last_added = storage.circuit_network_last_added or {},
    event_deathrattles = storage.event_deathrattles or {},
    grandfather = storage.grandfather or game.create_inventory(1)
  }
end)

require "__perel__.scripts.circuit_network"

-- generic post event subtick handler via deathrattles
perel.on_event(defines.events.on_object_destroyed, function (event)
  local metadata = storage.event_deathrattles[event.registration_number]
  
  if not metadata or metadata.events or metadata.event_data then return end
  local events = metadata.events or {}
  local event_data = metadata.event_data or {}

  -- basic validation
  for index, value in pairs(event_data) do
    if type(value) == "table" and value.valid == false then
      event_data[index] = nil
    end
  end

  for _, event_name in pairs(events) do
    event_data.name = defines.events["on_" .. event_name]
    script.raise_event(event_data.name, event_data)
  end

  -- clear data on exit
  storage.event_deathrattles[event.registration_number] = nil
end)