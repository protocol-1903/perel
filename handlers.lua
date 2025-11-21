assert(prototypes.item.coin, "ERROR: item 'coin' not found!")

perel = perel or {}

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

perel.event_handlers = {}

-- save event for later when registered
perel.on_event = function(event, handler)
  for _, event_id in pairs(type(event) == "table" and event or {event}) do
    if not perel.event_handlers[event_id] then
      perel.event_handlers[event_id] = {}
      script.on_event(event_id, function(e)
        for _, handler in pairs(perel.event_handlers[event_id]) do handler(e) end
      end)
    end
    table.insert(perel.event_handlers[event_id], handler)
  end
end

-- same for init and config changed, merged for ease of use
perel.event_handlers.on_init = {}
perel.on_init = function(handler)
  table.insert(perel.event_handlers.on_init, handler)
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
  local num = script.register_on_object_destroyed(storage.grandfather[1].item)
  storage.grandfather.clear()
  return num
end

-- fires on_pre_ events and delays full event triggering
perel.delayed_fire_event = function(event_name, event_data)
  storage.event_deathrattles[perel.tock()] = {
    events = event_name,
    event_data = event_data
  }

  -- raise events
  event_data.name = defines.events["on_pre_" .. event_name]
  script.raise_event(event_data.name, event_data)
end

return perel