-- utility prototypes
data:extend{
  {
    type = "custom-input",
    name = "perel-build",
    linked_game_control = "build",
    key_sequence = ""
  },
  {
    type = "custom-input",
    name = "perel-build-shift",
    linked_game_control = "build-ghost",
    key_sequence = ""
  },
  {
    type = "custom-input",
    name = "perel-pipette",
    linked_game_control = "pipette",
    key_sequence = ""
  }
}

-- circuit network event handlers
data:extend{
  { -- fired regardless of entity type
    type = "custom-event",
    name = "on_pre_circuit_wire_added"
  },
  { -- fired regardless of entity type
    type = "custom-event",
    name = "on_circuit_wire_added"
  },
  { -- fired regardless of entity type
    type = "custom-event",
    name = "on_pre_circuit_wire_removed"
  },
  { -- fired regardless of entity type
    type = "custom-event",
    name = "on_circuit_wire_removed"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_pre_circuit_network_created"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_created"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_pre_circuit_network_destroyed"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_destroyed"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_pre_circuit_network_merged"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_merged"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_pre_circuit_network_split"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_split"
  }
}

-- electric network event handlers
data:extend{
  {
    type = "custom-event",
    name = "on_pre_electric_wire_added"
  },
  {
    type = "custom-event",
    name = "on_electric_wire_added"
  },
  {
    type = "custom-event",
    name = "on_pre_electric_wire_removed"
  },
  {
    type = "custom-event",
    name = "on_electric_wire_removed"
  },
  {
    type = "custom-event",
    name = "on_pre_electric_network_created"
  },
  {
    type = "custom-event",
    name = "on_electric_network_created"
  },
  {
    type = "custom-event",
    name = "on_pre_electric_network_destroyed"
  },
  {
    type = "custom-event",
    name = "on_electric_network_destroyed"
  },
  {
    type = "custom-event",
    name = "on_pre_electric_network_merged"
  },
  {
    type = "custom-event",
    name = "on_electric_network_merged"
  },
  {
    type = "custom-event",
    name = "on_pre_electric_network_split"
  },
  {
    type = "custom-event",
    name = "on_electric_network_split"
  }
}