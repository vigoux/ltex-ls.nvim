local M = {}

local cache = require 'ltex-ls.cache'
local externals = require 'ltex-ls.externals'
local utils = require 'ltex-ls.utils'

local function handle_option_update(client, key, updated_val, uri)
  -- FIXME(vigoux): this does a lot of little write operations on the cache file, maybe have
  --                something to delay cache write ?
  if not utils.check_config_key(key) then return end

  local ltex_settings = client.config.settings.ltex[key]
  local fpath = vim.uri_to_fname(uri)

  if not ltex_settings then
    -- Just push to the cache
    cache.update_cache(fpath, { [key] = updated_val })
    return
  end

  for lang, value in pairs(updated_val) do
    if ltex_settings[lang] then
      -- There are defined configuration for this language, not just the cache
      -- so check if there is not an external file where the user might want to append
      local external_files = vim.tbl_map(function(e) return e:sub(2) end, externals.filter(ltex_settings[lang]))

      if #external_files > 0 then

        -- User configured an external file, ask where to put the newly added thing

        table.insert(external_files, "Local cache file")
        vim.ui.select(external_files, {
          prompt = string.format('Where to store new "%s":', key),
          kind = "string"
        }, function(item, index)
          if not index then
            return
          elseif index == #external_files then
            -- The user asked to write into the cache
            cache.update_cache(fpath, { [key] = { [lang] = value } })
          else
            local destfile = io.open(item, "a")
            if destfile then
              destfile:write(table.concat(value, "\n"))
              destfile:close()
            else
              utils.log("Can't write to " .. item, vim.log.levels.ERROR)
            end
          end
        end)

      else
        cache.update_cache(fpath, { [key] = { [lang] = value } })
      end
    else
      cache.update_cache(fpath, { [key] = { [lang] = value } })
    end
  end
  client.checkDocument(uri)
end

function M.workspace_command(err, result, ctx, config)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if ctx.method ~= "workspace/executeCommand" or client.name ~= "ltex" then
    error "LTeX command handler invalid usage"
  end

  local command_name = ctx.params.command
  local arg = ctx.params.arguments[1]
  if command_name == "_ltex.addToDictionary" then
    handle_option_update(client, "dictionary",  arg.words, arg.uri)
  elseif command_name == "_ltex.hideFalsePositives" then
    handle_option_update(client, "hiddenFalsePositives", arg.falsePositives, arg.uri)
  elseif command_name == "_ltex.disableRules" then
    handle_option_update(client, "disabledRules", arg.ruleIds, arg.uri)
  end

  vim.lsp.handlers[ctx.method](err, result, ctx, config)
end

function M.workspace_configuration(err, result, ctx, config)
  local scope_uri = result.items[1].scopeUri

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local settings = client.config.settings.ltex

  local expanded = externals.expand_config(settings)
  expanded = cache.merge_with(vim.uri_to_fname(scope_uri), expanded)
  vim.pretty_print(expanded)
  return expanded
end

return M
