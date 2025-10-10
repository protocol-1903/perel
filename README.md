[![ko-fi](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white&style=for-the-badge)](https://ko-fi.com/protocol1903) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fperel&style=for-the-badge)](https://mods.factorio.com/mod/perel) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/K3fXMGVc4z) [![](https://img.shields.io/badge/Github-Source-green?style=for-the-badge)](https://github.com/protocol-1903/perel)

# Just another library mod with some custom runtime events

Includes intellisense integration if the mod file is unzipped in the working directory

`on_circuit_wire_added`, `on_circuit_wire_removed`, `on_circuit_network_created`, `on_circuit_network_destroyed`, `on_circuit_network_merged`, `on_circuit_network_split`: (`pre_` circuit events are also supported)
    - `uint` player_index: The index of the player that caused the event.
    - `uint` tick: Tick the event was generated.
    - `LuaEntity` source: The source entity of the wire connection.
    - `defines.wire_connector_id` source_connector_id: The source connector of the wire connection.
    - `LuaEntity` destination: The destination entity of the wire connection.
    - `defines.wire_connector_id` destination_connector_id: The destination connector of the wire connection.
    - `defines.wire_type` wire_type: The wire type of the connection.

Explicit support definitions (what events trigger what):
`on_pre_circuit_wire_added` supports the following: player placing wires on ghost and normal entities
`on_circuit_wire_added` supports the following: player placing wires on ghost and normal entities, platforms/robots/players/scripts(opt-in) building ghosts with ghost wires into entities that then create wires
`on_pre_circuit_wire_removed` supports the following: player removing wires from ghost and normal entities
`on_circuit_wire_removed` supports the following: player removing wires from ghost and normal entities, platforms/robots/players/scripts(opt-in)/environment destroying non-ghost entities with wires
`on_pre_circuit_network_created` supports the following: player placing wires on normal entities
`on_circuit_network_created` supports the following: player placing wires on ghost and normal entities, platforms/robots/players/scripts(opt-in) building ghosts with ghost wires into entities that then create wires
`on_pre_circuit_network_destroyed` supports the following: player removing wires from normal entities
`on_circuit_network_destroyed` supports the following: player removing wires from ghost and normal entities, platforms/robots/players/scripts(opt-in)/environment destroying non-ghost entities with wires
`on_pre_circuit_network_merged` supports the following: player placing wires on normal entities
`on_circuit_network_merged` supports the following: player placing wires on normal entities, platforms/robots/players/scripts(opt-in) building ghosts with ghost wires into entities that then create wires
`on_pre_circuit_network_split` supports the following: player removing wires from normal entities
`on_circuit_network_split` supports the following: player removing wires from normal entities, platforms/robots/players/scripts(opt-in)/environment destroying non-ghost entities with wires

A note on the split/merge events: If an entity is built that connects/destroyed that splits two separate networks, i.e. a power pole in a string of power poles with circuit network wires, the event will be fired once for every entity that connects to the entity that was changed. The source entity will be the entity of change, the destination will be the entity that changed.

TODO: add pre_ event support to the new interactions (platforms, robots, players, scripts)

If you have a mod idea, let me know and I can look into it.