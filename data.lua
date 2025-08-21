PEREL = PEREL or {}


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
    name = "perel-pipette",
    linked_game_control = "pipette",
    key_sequence = ""
  },
  {
    type = "simple-entity-with-owner",
    name = "perel-trigger-entity",
    icon = util.empty_icon().icon
  },
  {
    type = "custom-event",
    name = "on_circuit_wire_added"
  },
  {
    type = "custom-event",
    name = "on_circuit_wire_removed"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_created"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_destroyed"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_merged"
  },
  { -- only fired when both entities are non-ghosts
    type = "custom-event",
    name = "on_circuit_network_split"
  }
}