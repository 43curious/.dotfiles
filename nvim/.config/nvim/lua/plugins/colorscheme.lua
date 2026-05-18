return {
  {
    "everviolet/nvim",
    name = "evergarden",
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
      colorscheme = "evergarden",
    },
  },
}
