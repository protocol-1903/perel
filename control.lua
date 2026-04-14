require "handlers"

perel.on_init(function()
  _G.storage = {
    grandfather = storage.grandfather or game.create_inventory(1),
    event_deathrattles = storage.event_deathrattles or {}
  }
end)

require "scripts.network_events"
-- require "scripts.electric_network"