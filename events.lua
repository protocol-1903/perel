-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@class (partial) PEREL
---@field events PEREL.events
---@field enabled_events PEREL.enabled_events
---@field event_categories PEREL.event_categories
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

-- per-event special handlers ran before the event is sent
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
perel.event_categories = {
  circuit_wire =
    perel.enabled_events.pre_circuit_wire_added or
    perel.enabled_events.circuit_wire_added or
    perel.enabled_events.pre_circuit_wire_removed or
    perel.enabled_events.circuit_wire_removed,
  circuit_network =
    perel.enabled_events.pre_circuit_network_created or
    perel.enabled_events.circuit_network_created or
    perel.enabled_events.pre_circuit_network_destroyed or
    perel.enabled_events.circuit_network_destroyed or
    perel.enabled_events.pre_circuit_network_merged or
    perel.enabled_events.circuit_network_merged or
    perel.enabled_events.pre_circuit_network_split or
    perel.enabled_events.circuit_network_split,
  electric_wire =
    perel.enabled_events.pre_electric_wire_added or
    perel.enabled_events.electric_wire_added or
    perel.enabled_events.pre_electric_wire_removed or
    perel.enabled_events.electric_wire_removed,
  electric_network =
    perel.enabled_events.pre_electric_network_created or
    perel.enabled_events.electric_network_created or
    perel.enabled_events.pre_electric_network_destroyed or
    perel.enabled_events.electric_network_destroyed or
    perel.enabled_events.pre_electric_network_merged or
    perel.enabled_events.electric_network_merged or
    perel.enabled_events.pre_electric_network_split or
    perel.enabled_events.electric_network_split,
}

return perel
