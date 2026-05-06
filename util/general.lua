_G.perel = perel or {}

local mult_lookup = {
  int2str = {
    [0] = "",
    "k",
    "M",
    "G",
    "T",
    "P",
    "E",
    "Z",
    "Y",
    "R",
    "Q"
  },
  str2int = {
    ["k"] = 3,
    ["M"] = 6,
    ["G"] = 9,
    ["T"] = 12,
    ["P"] = 15,
    ["E"] = 18,
    ["Z"] = 21,
    ["Y"] = 24,
    ["R"] = 27,
    ["Q"] = 30
  }
}

---Parses an integer number into W
---@param power int
---@return data.Energy
perel.calculate_power = function(power)
  local exp = ("%e"):format(power)
  local mult = tonumber(exp:sub(-2))
  local pow = tonumber(exp:sub(1, -5)) * (10 ^ (mult % 3))
  return (pow >= 100 and "%d %sW" or "%.1f %sW"):format(pow, mult_lookup.int2str[(mult - mult % 3) / 3])
end

---Parses J or W into an integer number
---@param power data.Energy
---@return int
perel.parse_power = function(power)
  local mult = not tonumber(power:sub(1, -2)) and power:sub(-2, -2) or nil
  return (mult and power:sub(1, -3) or power:sub(1, -2)) *
    (power:sub(-1) == "J" and 60 or 1) *
    10 ^ (mult_lookup.str2int[mult] or 0)
end

perel.calculate_si = function(number)
  local exp = ("%e"):format(number)
  local mult = tonumber(exp:sub(-1))
  local pow = tonumber(exp:sub(1, -5)) * (10 ^ (mult % 3))
  return (mult >= 3 and "%.1f %s" or "%.2f %s"):format(pow, mult_lookup.int2str[(mult - mult % 3) / 3])
end

return perel