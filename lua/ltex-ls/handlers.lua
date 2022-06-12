local M = {}

local cache = require 'ltex-ls.cache'
local externals = require 'ltex-ls.externals'

local function handle_option_update(client, updated_val, uri)
  local ltex_settings = client.config.settings.ltex

  local fpath = vim.uri_to_fname(uri)
  cache.update_cache(fpath, updated_val)

  client.checkDocument(uri)
end

function M.workspace_command(err, result, ctx, config)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if ctx.method ~= "workspace/executeCommand" or client.name ~= "ltex" then
    error "LTeX command handler invalid usage"
  end

  local command_name = ctx.params.command
  local args = ctx.params.arguments
  if command_name == "_ltex.addToDictionary" then
    handle_option_update(client, { dictionnary = args[1].words }, args[1].uri)
  elseif command_name == "_ltex.hideFalsePositives" then
    handle_option_update(client, { hiddenFalsePositives = args[1].falsePositives }, args[1].uri)
  elseif command_name == "_ltex.disableRules" then
    handle_option_update(client, { disabledRules = args[1].ruleIds }, args[1].uri)
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
