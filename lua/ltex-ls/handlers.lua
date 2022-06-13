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
  elseif command_name == "_ltex.getServerStatus" then
    local tmpbuf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_option(tmpbuf, "bufhidden", "delete")
    vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, {
      "LTeX Server Status",
      string.format("PID: %d", result.processId),
      string.format("Wall-clock duration: %d s", result.wallClockDuration),
      string.format("CPU duration: %d s", result.cpuDuration),
      string.format("CPU usage: %d %%", result.cpuUsage * 100),
      string.format("Used memory: %d B", result.usedMemory),
      string.format("JVM memory: %d B", result.totalMemory),
    })
    if result.isChecking then
      vim.api.nvim_buf_set_lines(tmpbuf, -1, -1, false, {
        string.format("Currently checking: %s", result.documentUriBeingChecked)
      })
    end

    local winwidth = vim.api.nvim_win_get_width(0)
    local winheight = vim.api.nvim_win_get_height(0)

    local newwidth = math.floor(winwidth * 0.8)
    local newheight = math.floor(winheight * 0.8)

    local x = (winwidth - newwidth) / 2
    local y = (winheight - newheight) / 2
    local win = vim.api.nvim_open_win(tmpbuf, true, {
      relative = "editor",
      width = newwidth,
      height = newheight,
      focusable = true,
      style = "minimal",
      border = "rounded",
      noautocmd = true,
      row = y,
      col = x
    })

    vim.api.nvim_buf_set_keymap(tmpbuf, "n", "q", "", { silent = true, noremap = true, callback = function()
      vim.api.nvim_win_hide(win)
    end})
  end

  vim.lsp.handlers[ctx.method](err, result, ctx, config)
end

function M.workspace_configuration(err, result, ctx, config)
  local scope_uri = result.items[1].scopeUri

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local settings = client.config.settings.ltex

  local expanded = externals.expand_config(settings)
  expanded = cache.merge_with(vim.uri_to_fname(scope_uri), expanded)
  return expanded
end

return M
