return {
  {
    "everviolet/nvim",
    name = "evergarden",
    lazy = true,
    priority = 1000,
    opts = {
      theme = {
        variant = "fall",
        accent = "green",
      },
      editor = {
        transparent_background = true,
        float = {
          color = "none",
          solid_border = false,
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = vim.g.rex_terminal and "default" or "evergarden",
    },
  },
}
