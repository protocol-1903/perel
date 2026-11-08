-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@class (partial) PEREL
---@field mod_data PEREL.mod_data
perel = perel or {}

local mod_data = (data.raw["mod-data"] or {}).perel or {
  type = "mod-data",
  name = "perel",
  data = {}
}

data:extend{mod_data}
perel.mod_data = data.raw["mod-data"].perel.data --[[@as PEREL.mod_data]]

---@class PEREL.mod_data
---@field connection_category_overrides {[string]: {[string]: true?}}

perel.mod_data.connection_category_overrides = perel.mod_data.connection_category_overrides or {}
