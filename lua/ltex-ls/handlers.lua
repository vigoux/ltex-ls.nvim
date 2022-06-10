local M = {}

local cache = require 'ltex-ls.cache'

local function handle_option_update(client, updated_val, uri)
  local ltex_settings = client.config.settings.ltex

  local fpath = vim.uri_to_fname(uri)
  client.config.settings.ltex = cache.update_then_merge_with(fpath, updated_val, ltex_settings)

  client.notify("workspace/didChangeConfiguration")
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

return M
