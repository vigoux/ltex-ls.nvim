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

function M.log(msg, level, opts)
  vim.notify(string.format("[lext-ls.nvim]: %s", msg), level, opts or {})
end

function M.check_config_key(key)
  if not vim.tbl_contains(M.CONFIG_KEYS, key) then
    M.log(key .. " is not a configurable entry", vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.get_ltex_client()
  return (vim.lsp.get_active_clients { name = "ltex" })[1]
end

function M.append_file_to_langs(cfg, file)
  for lang, value in pairs(cfg) do
    table.insert(value, ":" .. file)
  end
end

return M
