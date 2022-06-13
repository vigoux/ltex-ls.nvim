local M = {}

local CACHE_FNAME = ".ltex_ls_cache.json"
local utils = require'ltex-ls.utils'

--- Reads the cache associated with filepath
function M.read_cache(filepath)
  local start_path = vim.fn.fnamemodify(filepath, ":p:h")
  local paths = vim.fs.find(CACHE_FNAME, {
    path = start_path, upward = true,
    stop = "/", type = "file" })

  if #paths == 0 then return {}, nil end

  local p = paths[1]

  local cfile = io.open(p, "r")
  if cfile then
    local success, jvalue = pcall(vim.json.decode, cfile:read("*a"))
    if success then
      cfile:close()
      return jvalue, p
    else
      return {}, p
    end
  else
    return {}, p
  end
end

function M.update_cache(filepath, content)
  local cache_content, fpath = M.read_cache(filepath)
  fpath = fpath or vim.fn.fnamemodify(filepath, ":p:h") .. "/" .. CACHE_FNAME

  for _, key in ipairs(utils.CONFIG_KEYS) do
    if content[key] then
      if cache_content[key] then
        for lang, additions in pairs(content[key] or {}) do
          if cache_content[key][lang] then
            vim.list_extend(cache_content[key][lang], additions)
          else
            cache_content[key][lang] = additions
          end
        end
      else
        cache_content[key] = content[key]
      end
    end
  end

  local cfile = io.open(fpath, "w")
  if cfile then
    cfile:write(vim.json.encode(cache_content))
    cfile:close()
  else
    vim.notify(string.format("[ltex-ls.nvim] Could not write cache to %s", fpath), vim.log.levels.ERROR)
  end
  return cache_content
end

function M.merge_with(filepath, orig_config)
  local cache, _ = M.read_cache(filepath)
  return vim.tbl_deep_extend("keep", cache, orig_config)
end

function M.update_then_merge_with(filepath, updated, orig_config)
  local cache = M.update_cache(filepath, updated)
  return vim.tbl_deep_extend("keep", cache, orig_config)
end

return M
