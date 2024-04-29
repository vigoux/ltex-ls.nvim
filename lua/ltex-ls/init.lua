local M = {}

local utils = require 'ltex-ls.utils'
local handlers = require 'ltex-ls.handlers'
local cache = require 'ltex-ls.cache'
local internal_config = require 'ltex-ls.config'

local ok, lspconfig = pcall(require, 'lspconfig')
local setup
if ok then
  setup = lspconfig.ltex.setup
else
  local augroup = vim.api.nvim_create_augroup("LTeX_NVIM", {})
  setup = function(config)
    local cfg = vim.deepcopy(config)
    cfg.name = "ltex"
    cfg.cmd = { "ltex-ls" }
    vim.api.nvim_create_autocmd("Filetype", {
      pattern = config.filetypes,
      group = augroup,
      callback = function()
        local newcfg = vim.deepcopy(cfg)
        newcfg.root_dir = vim.fs.dirname(vim.fs.find({'.git', cache.CACHE_FNAME}, { upward = true })[1])
        vim.lsp.start(newcfg)
      end
    })
  end
end

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

--- Wraps a function to be used as an LSP client-side command
---@param func fun(cmd: string, args: any[], client: vim.lsp.Client)
---@return  fun(cmd: any, ctx: any)
local function mk_command_handler(func)
  return function(cmd, ctx)
    local args = cmd.arguments[1]

    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client == nil then error("Undefined client ?") end

    func(cmd.command, args, client)

    client.request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = args.uri or curbuf_uri() } } })
  end
end

local default_config = {
  init_options = {
    customCapabilities = {
      workspaceSpecificConfiguration = true
    }
  },
  filetypes = { "tex", "markdown", "text" },
  on_init = function(client)
    -- A bunch of functions specific to the client
    client.checkDocument = function(uri)
    end

    client.serverStatus = function(handler)
      client.request("workspace/executeCommand", { command = "_ltex.getServerStatus", arguments = {} }, handler)
    end
  end,
  commands = {
    ["_ltex.addToDictionnary"] = mk_command_handler(function(cmd, args, client)
      handlers.handle_option_update(client, "dictionary", args.words)
    end),
    ["_ltex.hideFalsePositives"] = mk_command_handler(function(cmd, args, client)
      handlers.handle_option_update(client, "hiddenFalsePositives", args.falsePositives)
    end),
    ["_ltex.disableRules"] = mk_command_handler(function(cmd, args, client)
      handlers.handle_option_update(client, "disabledRules", args.ruleIds)
    end)
  },
  handlers = {
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
        vim.api.nvim_set_option_value("bufhidden", "delete", {buf = tmpbuf})
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
          border = internal_config.window_border,
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
  },
  DisableHere = {
    opts = {
      desc = "Insert magic comments to disable LTeX at this range (defaults to current line).",
      nargs = 0,
      range = true,
    },
    func = function(_, args)
      local buf = vim.api.nvim_get_current_buf()
      local commentstring = vim.api.nvim_get_option_value("commentstring", {buf=buf})

      -- FIXME(vigoux): there must be a better way to handle that case... But the the default
      --                commentstring for latex.
      if commentstring == "%%s" then
        commentstring = "%% %s"
      end

      vim.api.nvim_buf_set_lines(buf, args.line1 - 1, args.line1 - 1, true, {
        string.format(commentstring, "LTeX: enabled=false")
      })
      vim.api.nvim_buf_set_lines(buf, args.line2 + 1, args.line2 + 1, true, {
        string.format(commentstring, "LTeX: enabled=true")
      })
    end
  }
}


--- Setup ltex-ls to integrate with neovim
--- This assumes that config matches what lspconfig expects
function M.setup(user_config)
  for name, spec in pairs(commands) do
    vim.api.nvim_create_user_command("Ltex" .. name, with_ltex(spec.func), spec.opts)
  end

  vim.tbl_extend("force", internal_config, user_config)

  local new_tbl = vim.tbl_deep_extend("force", default_config, user_config)
  setup(new_tbl)
end

return M
