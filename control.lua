-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

require "handlers"

perel.on_init(function()
  _G.storage = {
    grandfather = storage.grandfather or game.create_inventory(1),
    event_deathrattles = storage.event_deathrattles or {}
  }
end)

require "scripts.network_events"
