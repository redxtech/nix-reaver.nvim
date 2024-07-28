# nix-reaver-nvim

a neovim plugin to update nix fetchers to the latest commit hash.

## installation

install using your favorite package manager:

### lazy.nvim
```lua
{
  'redxtech/nix-reaver-nvim',
  keys = {
    { 'n', '<leader>ur', ':NixReaver<cr>' },
  },
  config = true,
}
```

## Usage

Run `:NixReaver` within a `fetchFromGitHub` function call to update the rev and hash the latest commit.

## todo

- [ ] add support for other fetchers
- [ ] add support for other branches, tags, etc
