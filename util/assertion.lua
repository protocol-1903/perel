-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

---@type PEREL
perel = perel or {}

---Fancy assert variant
---@param value any?
---@param e string error message
---@return boolean
perel.assert = function (value, e, ...)
  if value then return true end
  error(... and e:format(...) or e or "ERROR: perel.assert failed", 2)
  return false
end

---@enum (key) perel.value_type
local _value_type = {
  ["nil"] = 0,
  ["string"] = 1,
  ["table"] = 2,
  ["number"] = 3,
  ["userdata"] = 4,
  ["function"] = 5,
  ["boolean"] = 6,
  ["int"] = 7,
  ["uint"] = 8,
  ["nonzero"] = 9,
  ["gtzero"] = 10,
  ["ltzero"] = 11,
  ["gteqzero"] = 12,
  ["lteqzero"] = 13,
  ["energy"] = 14,
  ["mapposition"] = 15
}

---@type {[perel.value_type]: fun(value: any): boolean}
local type_checks = {
  ["nil"]         = function (value) return value == nil end,
  ["string"]      = function (value) return type(value) == "string" end,
  ["table"]       = function (value) return type(value) == "table" end,
  ["number"]      = function (value) return type(value) == "number" end,
  ["userdata"]    = function (value) return type(value) == "userdata" end,
  ["function"]    = function (value) return type(value) == "function" end,
  ["boolean"]     = function (value) return type(value) == "boolean" end,
  ["int"]         = function (value) return type(value) == "number" and math.floor(value) == value end,
  ["uint"]        = function (value) return type(value) == "number" and math.floor(value) == value and value >= 0 end,
  ["nonzero"]     = function (value) return type(value) == "number" and value ~= 0 end,
  ["gtzero"]      = function (value) return type(value) == "number" and value > 0 end,
  ["ltzero"]      = function (value) return type(value) == "number" and value < 0 end,
  ["gteqzero"]    = function (value) return type(value) == "number" and value >= 0 end,
  ["lteqzero"]    = function (value) return type(value) == "number" and value <= 0 end,
  ["energy"]      = function (value) return type(value) == "string" and value:sub(-1) == "W" or value:sub(-1) == "J" and not not tonumber(value:sub(1,1)) end,
  ["mapposition"] = function (value) return type(value) == "table" and not not (value[1] and value[2] or value.x and value.y) end
}

---@type {[perel.value_type]: string}
local type_errors = {
  nonzero     = ". Number must be != 0, found %q",
  gtzero      = ". Number must be > 0, found %q",
  ltzero      = ". Number must be < 0, found %q",
  gteqzero    = ". Number must be >= 0, found %q",
  lteqzero    = ". Number must be <= 0, found %q",
  energy      = ". Expected energy, found %q",
  mapposition = ". Expected energy, found %q",
}

---Fancy assert variant, typed
---@param value any?
---@param type perel.value_type|perel.value_type[]? type(s) to check
---@param e string error message
---@return boolean
perel.type_assert = function (value, type, e, ...)
  type = type or "nil"
  if _G.type(type) == "table" then
    for _, t in pairs(type --[[@as perel.value_type[] ]]) do
      if _G.type(t) ~= "string" or not type_checks[t] then
        error(("Error while running perel.type_assert(): unknown type %s"):format(t), 2)
      elseif not perel.type_assert(value, t, e, ...) then
        return false
      end
    end
    return true
  elseif _G.type(type) ~= "string" or not type_checks[type] then
    error(("Error while running perel.type_assert(): unknown type %s"):format(type), 2)
  elseif type_checks[type](value) then
    return true
  end
  ---@cast type perel.value_type
  error((... and e:format(...) or e or "ERROR: perel.assert failed") .. (type_errors[type] and type_errors[type]:format(value) or (". Expected %s, found %s"):format(type, _G.type(value))), 2)
  return false
end

---Soft assert variant. Will log optional message if assert fails
---@param value any?
---@param m string? log message
---@return boolean
perel.soft_assert = function (value, m, ...)
  if value then return true end
  if m then log(... and m:format(...) or m) end
  return false
end

---Soft assert variant, typed. Will log optional message if assert fails
---@param value any?
---@param type perel.value_type|perel.value_type[]? type(s) to check
---@param m string? log message
---@return boolean
perel.soft_type_assert = function (value, type, m, ...)
  type = type or "nil"
  if _G.type(type) == "table" then
    for _, t in pairs(type --[[@as perel.value_type[] ]]) do
      if _G.type(t) ~= "string" or not type_checks[t] then
        error(("Error while running perel.soft_type_assert(): unknown type %s"):format(t), 2)
      elseif not perel.soft_type_assert(value, t, m, ...) then
        return false
      end
    end
    return true
  elseif _G.type(type) ~= "string" or not type_checks[type] then
    error(("Error while running perel.soft_type_assert(): unknown type %s"):format(type), 2)
  elseif type_checks[type](value) then
    return true
  end
  ---@cast type perel.value_type
  if m then error((... and m:format(...) or m) .. (type_errors[type] and type_errors[type]:format(value) or (". Expected %s, found %s"):format(type, _G.type(value))), 2) end
  return false
end