local M = {}

local ok, lspconfig = pcall(require, 'lspconfig')
if not ok then
  error "ltex-ls.nvim requires 'nvim-lspconfig' to be installed"
end

local utils = require 'ltex-ls.utils'
local handlers = require 'ltex-ls.handlers'
local cache = require 'ltex-ls.cache'

local default_config = {
  on_init = function(client)
    -- Read false positives cache if present
    local new_config = cache.read_cache(vim.fn.expand "%")
    new_config = vim.tbl_deep_extend("keep", new_config, client.config.settings.ltex)

    -- TODO: do more things in here

    client.config.settings.ltex = new_config
    client.notify("workspace/didChangeConfiguration")

    -- A bunch of functions specific to the client
    client.checkDocument = function(uri)
      client.request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { { uri = uri } } })
    end
  end,
  handlers = {
    ["workspace/executeCommand"] = handlers.workspace_command
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
