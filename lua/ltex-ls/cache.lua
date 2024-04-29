local M = {}

M.CACHE_FNAME = ".ltex_ls_cache.json"
local utils = require'ltex-ls.utils'

local function write_cache(destination, content)
  local cfile = io.open(destination, "w")
  if cfile then
    cfile:write(vim.json.encode(content))
    cfile:close()
  else
    vim.notify(string.format("[ltex-ls.nvim] Could not write cache to %s", destination), vim.log.levels.ERROR)
  end
end

--- Get the path to use for the cache
---@param client vim.lsp.Client
---@return string path The path to the cache
local function get_cache_path(client)
  return vim.fs.joinpath(client.root_dir, M.CACHE_FNAME)
end

--- Reads the cache associated with filepath
function M.read(client)
  local p = get_cache_path(client)

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

function M.update(client, content)
  local cache_content, fpath = M.read(client)

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

  write_cache(fpath, cache_content)
  return cache_content
end

function M.clear(client, key)
  local content, path = M.read(client)
  if not key then
    os.remove(path)
  else
    content[key] = nil
    write_cache(path, content)
  end
end

function M.merge_with(client, orig_config)
  local cache, _ = M.read(client)
  return vim.tbl_deep_extend("keep", cache, orig_config)
end

function M.update_then_merge_with(client, updated, orig_config)
  local cache = M.update(client, updated)
  return vim.tbl_deep_extend("keep", cache, orig_config)
end

return M
