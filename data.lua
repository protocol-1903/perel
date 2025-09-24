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
    name = "on_pre_circuit_wire_added"
  },
  {
    type = "custom-event",
    name = "on_circuit_wire_added"
  },
  {
    type = "custom-event",
    name = "on_pre_circuit_wire_removed"
  },
  {
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

do return end
-- intellisense definitions for when the mod is unpacked

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum defines.events
defines.events = {
  on_pre_circuit_wire_added = #{}--[[@as defines.events.on_pre_circuit_wire_added]],
  on_circuit_wire_added = #{}--[[@as defines.events.on_circuit_wire_added]],
  on_pre_circuit_wire_removed = #{}--[[@as defines.events.on_pre_circuit_wire_removed]],
  on_circuit_wire_removed = #{}--[[@as defines.events.on_circuit_wire_removed]],
  on_pre_circuit_network_created = #{}--[[@as defines.events.on_pre_circuit_network_created]],
  on_circuit_network_created = #{}--[[@as defines.events.on_circuit_network_created]],
  on_pre_circuit_network_destroyed = #{}--[[@as defines.events.on_pre_circuit_network_destroyed]],
  on_circuit_network_destroyed = #{}--[[@as defines.events.on_circuit_network_destroyed]],
  on_pre_circuit_network_merged = #{}--[[@as defines.events.on_pre_circuit_network_merged]],
  on_circuit_network_merged = #{}--[[@as defines.events.on_circuit_network_merged]],
  on_pre_circuit_network_split = #{}--[[@as defines.events.on_pre_circuit_network_split]],
  on_circuit_network_split = #{}--[[@as defines.events.on_circuit_network_split]]
}

---Called before a circuit wire is added between two entities.\
---Fired regardless of if either entity is a ghost.
---@class (exact) EventData.on_pre_circuit_wire_added : EventData
---The index of the player that added the wire connection.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the wire connection.
---@field source LuaEntity
---The source connector of the wire connection.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the wire connection.
---@field destination LuaEntity
---The destination connector of the wire connection.
---@field destination_connector_id defines.wire_connection_id
---The wire type used to make the connection.
---@field wire_type defines.wire_type

---Called when a circuit wire is added between two entities.\
---Fired regardless of if either entity is a ghost.\
---Also fired when ghosts are built and their wires are created.
---@class (exact) EventData.on_circuit_wire_added : EventData
---The index of the player that added the wire connection.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the wire connection.
---@field source LuaEntity
---The source connector of the wire connection.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the wire connection.
---@field destination LuaEntity
---The destination connector of the wire connection.
---@field destination_connector_id defines.wire_connection_id
---The wire type used to make the connection.
---@field wire_type defines.wire_type

---Called before a circuit wire is removed between two entities.\
---Fired regardless of if either entity is a ghost.
---@class (exact) EventData.on_pre_circuit_wire_removed : EventData
---The index of the player that removed the wire connection.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the wire removal.
---@field source LuaEntity
---The source connector of the wire removal.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the wire removal.
---@field destination LuaEntity
---The destination connector of the wire removal.
---@field destination_connector_id defines.wire_connection_id
---The wire type that was removed.
---@field wire_type defines.wire_type

---Called when a circuit wire is removed between two entities.\
---Fired regardless of if either entity is a ghost.\
---Also fired when ghosts are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_wire_removed : EventData
---The index of the player that removed the wire connection.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the wire removal.
---@field source LuaEntity
---The source connector of the wire removal.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the wire removal.
---@field destination LuaEntity
---The destination connector of the wire removal.
---@field destination_connector_id defines.wire_connection_id
---The wire type that was removed.
---@field wire_type defines.wire_type

---Called before a circuit network is created between two entities.\
---Fired only when both entities are not ghosts.
---@class (exact) EventData.on_pre_circuit_network_created : EventData
---The index of the player that created the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the circuit network.
---@field source LuaEntity
---The source connector of the circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the circuit network.
---@field destination LuaEntity
---The destination connector of the circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the circuit network.
---@field wire_type defines.wire_type

---Called when a circuit network is created between two entities.\
---Fired only when both entities are not ghosts.\
---Also fired when ghosts are built and their wires are created.
---@class (exact) EventData.on_circuit_network_created : EventData
---The index of the player that created the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the circuit network.
---@field source LuaEntity
---The source connector of the circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the circuit network.
---@field destination LuaEntity
---The destination connector of the circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is destroyed.\
---Fired only when both entities are not ghosts.
---@class (exact) EventData.on_pre_circuit_network_destroyed : EventData
---The index of the player that destroyed the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the destroyed circuit network.
---@field source LuaEntity
---The source connector of the destroyed circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the destroyed circuit network.
---@field destination LuaEntity
---The destination connector of the destroyed circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the destroyed circuit network.
---@field wire_type defines.wire_type

---Called when a circuit network is destroyed.\
---Fired only when both entities are not ghosts.\
---Also fired when ghosts are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_network_destroyed : EventData
---The index of the player that destroyed the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the destroyed circuit network.
---@field source LuaEntity
---The source connector of the destroyed circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the destroyed circuit network.
---@field destination LuaEntity
---The destination connector of the destroyed circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the destroyed circuit network.
---@field wire_type defines.wire_type

---Called before two circuit networks are merged.\
---Fired only when both entities are not ghosts.
---@class (exact) EventData.on_pre_circuit_network_merged : EventData
---The index of the player that merged the networks.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the merged circuit network.
---@field source LuaEntity
---The source connector of the merged circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the merged circuit network.
---@field destination LuaEntity
---The destination connector of the merged circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the merged circuit network.
---@field wire_type defines.wire_type

---Called when two circuit networks are merged.\
---Fired only when both entities are not ghosts.\
---Also fired when ghosts are built and their wires are created.
---@class (exact) EventData.on_circuit_network_merged : EventData
---The index of the player that merged the networks.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the merged circuit network.
---@field source LuaEntity
---The source connector of the merged circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the merged circuit network.
---@field destination LuaEntity
---The destination connector of the merged circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the merged circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is split.\
---Fired only when both entities are not ghosts.
---@class (exact) EventData.on_pre_circuit_network_split : EventData
---The index of the player that split the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the split circuit network.
---@field source LuaEntity
---The source connector of the split circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the split circuit network.
---@field destination LuaEntity
---The destination connector of the split circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the split circuit network.
---@field wire_type defines.wire_type

---Called when a circuit network is split.\
---Fired only when both entities are not ghosts.\
---Also fired when ghosts are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_network_split : EventData
---The index of the player that split the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the split circuit network.
---@field source LuaEntity
---The source connector of the split circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the split circuit network.
---@field destination LuaEntity
---The destination connector of the split circuit network.
---@field destination_connector_id defines.wire_connection_id
---The wire type of the split circuit network.
---@field wire_type defines.wire_type