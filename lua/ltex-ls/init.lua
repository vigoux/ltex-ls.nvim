local M = {}

local ok, lspconfig = pcall(require, 'lspconfig')
if not ok then
  error "ltex-ls.nvim requires 'nvim-lspconfig' to be installed"
end

local utils = require 'ltex-ls.utils'
local handlers = require 'ltex-ls.handlers'
local cache = require 'ltex-ls.cache'

local default_config = {
  init_options = {
    customCapabilities = {
      workspaceSpecificConfiguration = true
    }
  },
  on_init = function(client)
    client.config.settings.ltex = cache.merge_with(vim.fn.expand "%", client.config.settings.ltex)
    client.notify("workspace/didChangeConfiguration")

    -- A bunch of functions specific to the client
    client.checkDocument = function(uri)
      client.request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = uri } } })
    end
  end,
  handlers = {
    ["workspace/executeCommand"] = handlers.workspace_command,
    ["ltex/workspaceSpecificConfiguration"] = handlers.workspace_configuration
  },
  settings = {
    ltex = {
      -- Empty for now but fill up later
    },
  },
}


--- Setup ltex-ls to integrate with neovim
--- This assumes that config matches what lspconfig expects
function M.setup(user_config)
  local new_tbl = vim.tbl_deep_extend("force", default_config, user_config)
  lspconfig.ltex.setup(new_tbl)
end

return M
