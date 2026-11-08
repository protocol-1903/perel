-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@class (partial) PEREL
---@field special_handlers {[string]: fun(event: EventData): boolean?}
---@field on_event fun(event: defines.events|defines.events[]|defines.events[][]|string|string[], handler: fun(event: EventData))
---@field on_init fun(handler: fun(event: ConfigurationChangedData?))
---@field tock fun(): uint64, uint64, defines.target_type -- Register an object then immediately destroy it, triggering a subtick event
---@field remove_invalid fun(table: table<any, any>) -- Recursively removes invalid userdata objects
---@field fire_event fun(event_name: string, event_data: EventData) -- Immediately fires event, if enabled
---@field delayed_fire_event fun(event_name: string, event_data: EventData, skip_pre_fire_event: boolean?) -- Fires on_pre_ events and delays full event triggering, if enabled
perel = perel or {}

require "events"

---@diagnostic disable-next-line: assign-type-mismatch
---@class (partial) PEREL.storage
storage = storage or {}

assert(prototypes.item.coin, "ERROR: item 'coin' not found!")

---@type {[defines.events|string]: fun(e)[]}
local event_handlers = {}

---@param event defines.events|defines.events[]|defines.events[][]|string|string[]
---@param handler fun(event: EventData)
perel.on_event = function(event, handler)
  if type(event) == "table" then
    for _, event_id in pairs(event) do
      perel.on_event(event_id, handler)
    end
  elseif event then
    if not event_handlers[event] then
      event_handlers[event] = {}
      script.on_event(event, function(e)
        for _, handle in pairs(event_handlers[event]) do handle(e) end
      end)
    end
    event_handlers[event][#event_handlers[event]+1] = handler
  end
end

event_handlers.on_init = {}

---@param handler fun(event: ConfigurationChangedData?)
perel.on_init = function(handler)
  event_handlers.on_init[#event_handlers.on_init+1] = handler
end

script.on_init(function(e)
  for _, handler in pairs(event_handlers.on_init) do handler(e) end
end)

script.on_configuration_changed(function(e)
  for _, handler in pairs(event_handlers.on_init) do handler(e) end
end)

---Register an object then immediately destroy it, triggering a subtick event
---@return uint64, uint64, defines.target_type
perel.tock = function()
  storage.grandfather.insert{name = "coin", health = 0.5}
  ---@diagnostic disable-next-line: param-type-mismatch
  local num, num2, type = script.register_on_object_destroyed(storage.grandfather[1].item)
  storage.grandfather.clear()
  return num, num2, type
end

---Recursively removes invalid userdata objects
---@param table table<any, any>
perel.remove_invalid = function(table)
  for index, value in pairs(table) do
    if type(value) == "userdata" and value.valid == false then
      table[index] = nil
    elseif type(value) == "table" then -- table of data, check individually
      perel.remove_invalid(value)
    end
  end
end

---Immediately fires event, if enabled
---@param event_name string
---@param event_data EventData
perel.fire_event = function(event_name, event_data)
  if not event_name or not event_data then return end
  if not perel.enabled_events[event_name] then return end
  event_data.name = defines.events["on_" .. event_name]
  script.raise_event(event_data.name, event_data)
end

---Fires on_pre_ events and delays full event triggering, if enabled
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

---@type {[string]: fun(e: EventData): boolean?}
perel.special_handlers = {}

---Generic post event subtick handler via deathrattles
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
  if perel.special_handlers[event_name] and perel.special_handlers[event_name](event_data) or not perel.special_handlers[event_name] then
    perel.fire_event(event_name, event_data)
  end
end)

return perel
