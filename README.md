[![ko-fi](https://img.shields.io/badge/Ko--fi-Donate%20-hotpink?logo=kofi&logoColor=white&style=for-the-badge)](https://ko-fi.com/protocol1903) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Fperel&style=for-the-badge)](https://mods.factorio.com/mod/perel) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/K3fXMGVc4z) [![](https://img.shields.io/badge/Github-Source-green?style=for-the-badge)](https://github.com/protocol-1903/perel)

# Just another library mod with some custom runtime events

`on_circuit_wire_added`, `on_circuit_wire_removed`, `on_circuit_network_created`, `on_circuit_network_destroyed`, `on_circuit_network_merged`, `on_circuit_network_split`:
    - `uint` player_index: The index of the player that caused the event.
    - `uint` tick: Tick the event was generated.
    - `LuaEntity` source: The source entity of the wire connection.
    - `defines.wire_connector_id` source_connector_id: The source connector of the wire connection.
    - `LuaEntity` destination: The destination entity of the wire connection.
    - `defines.wire_connector_id` destination_connector_id: The destination connector of the wire connection.
    - `defines.wire_type` wire_type: The wire type of the connection.

NOTE: Circuit network events currently only support player interaction. Script/bot interaction is planned for the future.

If you have a mod idea, let me know and I can look into it.