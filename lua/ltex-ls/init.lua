local M = {}

local ok, lspconfig = pcall(require, 'lspconfig')
if not ok then
  error "ltex-ls.nvim requires 'nvim-lspconfig' to be installed"
end

local utils = require 'ltex-ls.utils'
local handlers = require 'ltex-ls.handlers'
local cache = require 'ltex-ls.cache'
local internal_config = require 'ltex-ls.config'

local function with_ltex(func)
  return function(...)
    local client = utils.get_ltex_client()
    if not client then return end
    func(client, ...)
  end
end

local function curbuf_uri()
  return vim.uri_from_bufnr(vim.api.nvim_get_current_buf())
end

local default_config = {
  init_options = {
    customCapabilities = {
      workspaceSpecificConfiguration = true
    }
  },
  on_init = function(client)
    -- A bunch of functions specific to the client
    client.checkDocument = function(uri)
      uri = uri or curbuf_uri()
      client.request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = uri } } })
    end

    client.serverStatus = function(handler)
      client.request("workspace/executeCommand", { command = "_ltex.getServerStatus", arguments = {} }, handler)
    end
  end,
  handlers = {
    ["workspace/executeCommand"] = handlers.workspace_command,
    ["ltex/workspaceSpecificConfiguration"] = handlers.workspace_configuration
  },
}

local commands = {
  CheckDocument = {
    func = function(client)
      client.checkDocument()
    end,
    opts = { desc = "Checks the current buffer with LTeX" }
  },
  ClearCache = {
    func = function(client)
      local path = vim.fn.expand "%"
      vim.ui.select(vim.list_extend(vim.deepcopy(utils.CONFIG_KEYS), { "all" }), {
        prompt = "Which key do you want to clear:",
        kind = "string"
      }, function(item)
        if not item then
          return
        elseif item == "all" then
          cache.clear(path)
        else
          cache.clear(path, item)
        end
        client.checkDocument()
      end)
    end,
    opts = { desc = "Deletes parts of or all of the cache" }
  },
  ServerStatus = {
    func = function(client)
      client.serverStatus(function(err, result)
        if err then
          utils.log(vim.inspect(err), vim.log.levels.ERROR)
          return
        end
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
        end })
      end)
    end,
    opts = { desc = "Displays the server status in a floating window" }
  }
}


--- Setup ltex-ls to integrate with neovim
--- This assumes that config matches what lspconfig expects
function M.setup(user_config)
  for name, spec in pairs(commands) do
    vim.api.nvim_create_user_command("Ltex" .. name, with_ltex(spec.func), spec.opts)
  end

  internal_config.log_level = user_config.log_level
  internal_config.use_spellfile = user_config.use_spellfile

  local new_tbl = vim.tbl_deep_extend("force", default_config, user_config)
  lspconfig.ltex.setup(new_tbl)
end

return M
