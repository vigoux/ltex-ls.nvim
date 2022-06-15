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

As this plugin is a wrapper around `lspconfig` here how to run it:
```lua
require'ltex-ls'.setup {
  use_spellfile = false, -- Uses the value of 'spellfile' as an external file when checking the document
  -- Put your lsp config here, just like with nvim-lspconfig
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
- [ ] Allow to clear the cache
