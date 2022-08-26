local M = {
  log_level = vim.log.levels.ERROR,
  use_spellfile = false,
  window_border = "single",
}

local function cfg_index(cfg, key)
  if key == "spellfile" then
    if M.use_spellfile then
      return vim.api.nvim_buf_get_option(0, "spellfile")
    else
      return ""
    end
  end

  return rawget(table, key)
end

setmetatable(M, { __index = cfg_index })

return M
