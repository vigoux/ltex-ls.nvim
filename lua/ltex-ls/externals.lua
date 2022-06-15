local M = {}

local utils = require'ltex-ls.utils'

local function expand_one(lst)
  local new = {}
  for lname, value in pairs(lst) do
    new[lname] = {}
    for _, item in ipairs(value) do
      if item:sub(1, 1) == ':' then
        local ok, lines = pcall(io.lines, item:sub(2))
        if ok then
          for line in lines do
            table.insert(new[lname], line)
          end
        end
      else
        table.insert(new[lname], item)
      end
    end
  end
  return new
end

function M.expand_config(cfg)
  local new_c = {}
  for _, key in ipairs(utils.CONFIG_KEYS) do
    if cfg[key] then
      new_c[key] = expand_one(cfg[key])
    end
  end
  return new_c
end

function M.filter(tbl)
  return vim.tbl_filter(function(e) return vim.startswith(e, ':') end, tbl)
end

return M
