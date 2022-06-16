# ltex-ls.nvim

Enhanced integration of [`ltex-ls`](https://valentjn.github.io/ltex) for neovim.

Features:
- Integration with `nvim` options:
  - `spellfile`
- Working code-actions for:
  - `Add to dictionnary`
  - `Disable rule`
  - `Hide false positive`
- [External files](https://valentjn.github.io/ltex/vscode-ltex/setting-scopes-files.html#external-setting-files) support
- See TODO section for the planned work

## Installation

Install this plugin using your favorite package manager.
Remember that this plugin requires using `nvim-lspconfig`.
```lua

use { 'vigoux/ltex-ls.nvim', requires = 'neovim/nvim-lspconfig' }
```

## Usage

As this plugin is a wrapper around `lspconfig` here how to run it:
```lua
require'ltex-ls'.setup {
  use_spellfile = false, -- Uses the value of 'spellfile' as an external file when checking the document
  -- Put your lsp config here, just like with nvim-lspconfig
}
```

The plugin exposes multiple commands to help to interact with the
server:
- `LtexCheckDocument`: checks the current buffer
- `LtexClearCache`: using a simple ui, clears parts of or all the
  local config
- `LtexServerStatus`: very simple status report of the server, useful
  for debugging

For example (with my own config):
```lua
require 'ltex-ls'.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  use_spellfile = false,
  filetypes = { "latex", "tex", "bib", "markdown", "gitcommit", "text" },
  settings = {
    ltex = {
      enabled = { "latex", "tex", "bib", "markdown", },
      language = "auto",
      diagnosticSeverity = "information",
      sentenceCacheSize = 2000,
      additionalRules = {
        enablePickyRules = true,
        motherTongue = "fr",
      },
      disabledRules = {
        fr = { "APOS_TYP", "FRENCH_WHITESPACE" }
      },
      dictionary = (function()
        -- For dictionary, search for files in the runtime to have
        -- and include them as externals the format for them is
        -- dict/{LANG}.txt
        --
        -- Also add dict/default.txt to all of them
        local files = {}
        for _, file in ipairs(vim.api.nvim_get_runtime_file("dict/*", true)) do
          local lang = vim.fn.fnamemodify(file, ":t:r")
          local fullpath = vim.fs.normalize(file, ":p")
          files[lang] = { ":" .. fullpath }
        end

        if files.default then
          for lang, _ in pairs(files) do
            if lang ~= "default" then
              vim.list_extend(files[lang], files.default)
            end
          end
          files.default = nil
        end
        return files
      end)(),
    },
  },
}
```
## TODOs

- [ ] Integrate `spelllang` into `ltex.language`
- [x] Integrate `spellfile` into `ltex.dictionnary`
- [x] Support custom commands
  - [x] `_ltex.addToDictionary`
  - [x] `_ltex.disableRules`
  - [x] `_ltex.hideFalsePositives`
  - [x] `_ltex.checkDocument`
    - [x] Expose with `:LtexCheckDocument`
  - [x] `_ltex.getServerStatus`
    - [x] Expose `:LtexServerStatus`
- [x] _Workspace_ configuration with `ltex/workspaceSpecificConfiguration`
- [x] Allow to clear the cache
