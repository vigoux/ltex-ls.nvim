# ltex-ls.nvim

Enhanced integration of ltex-ls for neovim

Features:
- Working code-actions for:
  - `Add to dictionnary`
  - `Disable rule`
  - `Hide false positive`
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
  -- Put your lsp config here, just like with nvim-lspconfig
}
```
## TODOs

- [ ] Integrate `spelllang` inte `ltes.language`
- [ ] Integrate `spellfile` into `ltex.dictionnary`
  - [x] Add [external files](https://valentjn.github.io/ltex/vscode-ltex/setting-scopes-files.html#external-setting-files) support
- [ ] Support custom commands
  - [x] `_ltex.addToDictionary`
    - [ ] Expose `:LtexAddToDictionnary`
  - [x] `_ltex.disableRules`
    - [ ] Expose `:LtexDisableRule`
  - [x] `_ltex.hideFalsePositives`
    - [ ] Expose `:LtexHideFalsePositive`
  - [x] `_ltex.checkDocument`
    - [ ] Expose with `:LtexCheckDocument`
  - [ ] `_ltex.getServerStatus`
- [x] _Workspace_ configuration with `ltex/workspaceSpecificConfiguration`
- [ ] Allow to clear the cache
