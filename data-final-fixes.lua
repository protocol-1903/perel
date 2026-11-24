for index, fun in pairs(perel.postprocess) do
  log("calling postprocess function: " .. index)
  fun()
end