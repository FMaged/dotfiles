-- gruvbox dark, to match the terminal (#282828 background) and zellij's gruvbox-dark theme
return {
  { "ellisonleao/gruvbox.nvim", priority = 1000, opts = {} },
  { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
