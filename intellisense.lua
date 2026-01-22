-- intellisense definitions for when the mod is unpacked
---@meta

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
---@field destination_connector_id defines.wire_connector_id
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
---@field destination_connector_id defines.wire_connector_id
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
---@field destination_connector_id defines.wire_connector_id
---The wire type that was removed.
---@field wire_type defines.wire_type

---Called when a circuit wire is removed between two entities.\
---Fired regardless of if either entity is a ghost.\
---Also fired when entities (not ghosts) are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_wire_removed : EventData
---The index of the player that removed the wire connection.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the wire removal. May not exist if the entity was destroyed.
---@field source LuaEntity
---The source connector of the wire removal.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the wire removal. May not exist if the entity was destroyed.
---@field destination LuaEntity
---The destination connector of the wire removal.
---@field destination_connector_id defines.wire_connector_id
---The wire type that was removed.
---@field wire_type defines.wire_type

---Called before a circuit network is created.\
---Does not fire for ghost networks.
---@class (exact) EventData.on_pre_circuit_network_created : EventData
---The index of the player that created the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the created circuit network.
---@field source LuaEntity
---The source connector of the created circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is created.\
---Does not fire for ghost networks.\
---Also fired when ghosts are built and their wires are created.
---@class (exact) EventData.on_circuit_network_created : EventData
---The index of the player that created the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the created circuit network.
---@field source LuaEntity
---The source connector of the created circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is destroyed.\
---Does not fire for ghost networks.
---@class (exact) EventData.on_pre_circuit_network_destroyed : EventData
---The index of the player that destroyed the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the destroyed circuit network.
---@field source LuaEntity
---The source connector of the destroyed circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the destroyed circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is destroyed.\
---Does not fire for ghost networks.\
---Also fired when entities are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_network_destroyed : EventData
---The index of the player that destroyed the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the destroyed circuit network. May not exist if the entity was destroyed.
---@field source LuaEntity
---The source connector of the destroyed circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the destroyed circuit network. May not exist if the entity was destroyed.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the destroyed circuit network.
---@field wire_type defines.wire_type

---Called before two circuit networks are merged.\
---Does not fire for ghost networks.
---@class (exact) EventData.on_pre_circuit_network_merged : EventData
---The index of the player that merged the networks.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the merged circuit network.
---@field source LuaEntity
---The source connector of the merged circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the merged circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the merged circuit network.
---@field wire_type defines.wire_type

---Called when two circuit networks are merged.\
---Does not fire for ghost networks.\
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
---The destination entities of the merged circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the merged circuit network.
---@field wire_type defines.wire_type

---Called before a circuit network is split.\
---Does not fire for ghost networks.
---@class (exact) EventData.on_pre_circuit_network_split : EventData
---The index of the player that split the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the split circuit network.
---@field source LuaEntity
---The source connector of the split circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entities of the split circuit network.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the split circuit network.
---@field wire_type defines.wire_type

---Called when a circuit network is split.\
---Does not fire for ghost networks.
---Also fired when entities are destroyed and their wires are removed.
---@class (exact) EventData.on_circuit_network_split : EventData
---The index of the player that split the network.
---@field player_index uint
---Tick the event was generated.
---@field tick uint
---The source entity of the split circuit network. May not exist if the entity was destroyed.
---@field source LuaEntity
---The source connector of the split circuit network.
---@field source_connector_id defines.wire_connector_id
---The destination entity of the split circuit network. May not exist if the entity was destroyed.
---@field destinations {["entity"]:LuaEntity, ["connector_id"]:defines.wire_connector_id}[]
---The wire type of the split circuit network.
---@field wire_type defines.wire_type