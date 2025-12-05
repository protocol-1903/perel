-- create a hidden mod setting for every event we use, enableable per-event as mods need them
for _, event_name in pairs{
  "pre_circuit_wire_added",
  "circuit_wire_added",
  "pre_circuit_wire_removed",
  "circuit_wire_removed",
  "pre_circuit_network_created",
  "circuit_network_created",
  "pre_circuit_network_destroyed",
  "circuit_network_destroyed",
  "pre_circuit_network_merged",
  "circuit_network_merged",
  "pre_circuit_network_split",
  "circuit_network_split",
  "pre_electric_wire_added",
  "electric_wire_added",
  "pre_electric_wire_removed",
  "electric_wire_removed",
  "pre_electric_network_created",
  "electric_network_created",
  "pre_electric_network_destroyed",
  "electric_network_destroyed",
  "pre_electric_network_merged",
  "electric_network_merged",
  "pre_electric_network_split",
  "electric_network_split",
} do
  data:extend{{
    type = "bool-setting",
    setting_type = "startup",
    name = "perel_" .. event_name,
    hidden = true,
    default_value = false,
    forced_value = false
  }}
end

-- create an mod setting to turn on all events
data:extend{{
  type = "bool-setting",
  setting_type = "startup",
  name = "perel-enable-all-events",
  hidden = true,
  default_value = false,
  forced_value = false
}}