local M = {
  CONFIG_KEYS = { "dictionary", "disabledRules", "enabledRules", "hiddenFalsePositives" }
}

function M.read_dictionnary_file(path)
  local lines = {}
  for line in io.lines(path) do
    table.insert(lines, line)
  end

  return lines
end

return M
