-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

require "handlers"

---@diagnostic disable-next-line: assign-type-mismatch
---@class (partial) PEREL.storage
---@field grandfather LuaInventory
---@field event_deathrattles {[uint64]: {event_name: string, event_data: EventData}}
storage = storage or {}

perel.on_init(function()
  storage.grandfather = storage.grandfather or game.create_inventory(1)
  storage.event_deathrattles = storage.event_deathrattles or {}
end)

perel.mod_data = prototypes.mod_data.perel.data --[[@as PEREL.mod_data]]

require "scripts.network_events"
