# ltex-ls.nvim

Enhanced integration of ltex-ls for neovim

# TODOs

- [ ] Integrate `spelllang` inte `ltes.language`
- [ ] Integrate `spellfile` into `ltex.dictionnary`
  - [ ] Add [external files](https://valentjn.github.io/ltex/vscode-ltex/setting-scopes-files.html#external-setting-files) support
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
- [ ] _Workspace_ configuration with `ltex/workspaceSpecificConfiguration`
