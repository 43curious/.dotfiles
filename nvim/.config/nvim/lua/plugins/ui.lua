local lazyvim_header = [[
██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗
██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║
██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║
██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║
███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝]]

local compact_header = [[
██╗      ██╗   ██╗
██║      ██║   ██║
██║      ██║   ██║
███████╗ ╚██████╔╝
╚══════╝  ╚═════╝]]

return {
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.component_separators = ""
      opts.options.section_separators = ""
      opts.options.theme = "auto"

      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        {
          "mode",
          fmt = function(mode)
            return ({ NORMAL = "N", INSERT = "I", VISUAL = "V", ["V-LINE"] = "V", ["V-BLOCK"] = "V" })[mode]
              or mode:sub(1, 1)
          end,
        },
      }
      opts.sections.lualine_b = {}
      opts.sections.lualine_c = {
        {
          "filename",
          path = 1,
          symbols = {
            modified = " [+]",
            readonly = " [ro]",
            unnamed = "[No Name]",
          },
        },
      }
      opts.sections.lualine_x = {}
      opts.sections.lualine_y = {}
      opts.sections.lualine_z = {}
    end,
  },
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        no_overlap = false,
        row = math.huge,
        col = 0,
        width = "100%",
        border = "none",
        padding = { 0, 1 },
        title = false,
      },
      layout = {
        spacing = 2,
      },
    },
    config = function(_, opts)
      local Win = require("which-key.win")

      if not Win._bottom_cmdline_patched then
        Win._bottom_cmdline_patched = true
        Win._bottom_cmdline_saved = nil

        local show = Win.show
        local hide = Win.hide

        function Win:show(show_opts)
          local height = (show_opts and show_opts.height) or self.opts.height or 8
          Win._bottom_cmdline_saved = Win._bottom_cmdline_saved or vim.o.cmdheight
          vim.o.cmdheight = math.max(Win._bottom_cmdline_saved, height + 1)

          show_opts = show_opts or {}
          show_opts.row = vim.o.lines - height - 1
          show_opts.col = 0
          show_opts.width = vim.o.columns

          show(self, show_opts)
        end

        function Win:hide(...)
          hide(self, ...)
          if Win._bottom_cmdline_saved then
            vim.o.cmdheight = Win._bottom_cmdline_saved
            Win._bottom_cmdline_saved = nil
          end
        end
      end

      local wk = require("which-key")
      wk.setup(opts)
      if opts.defaults and not vim.tbl_isempty(opts.defaults) then
        LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
        wk.register(opts.defaults)
      end
    end,
  },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.cmdline = opts.cmdline or {}
      opts.cmdline.enabled = true
      opts.cmdline.view = "cmdline"
      opts.presets = opts.presets or {}
      opts.presets.command_palette = false
    end,
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
    opts = function(_, opts)
      opts.scroll = { enabled = false }
      -- Keep Snacks for the picker/projects/etc., but do not use its file explorer.
      -- netrw is the default file explorer and handles directory buffers.
      opts.explorer = { enabled = false, replace_netrw = false }

      opts.picker = opts.picker or {}
      opts.picker.layout = {
        preset = "ivy_split",
        layout = {
          height = 0.35,
        },
      }
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.projects = vim.tbl_deep_extend("force", opts.picker.sources.projects or {}, {
        -- Open selected projects in netrw at the project root for <leader>fp.
        confirm = function(picker, item)
          picker:close()
          if not item then
            return
          end

          local dir = Snacks.picker.util.dir(item)
          vim.cmd.tcd(vim.fn.fnameescape(dir))
          vim.cmd.edit(vim.fn.fnameescape(dir))
        end,
      })

      opts.picker.sources.buffers = vim.tbl_deep_extend("force", opts.picker.sources.buffers or {}, {
        layout = {
          preset = "ivy_split",
          preview = false,
          layout = {
            height = 0.3,
          },
        },
      })

      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        layout = {
          preset = "ivy_split",
          preview = false,
          layout = {
            height = 0.35,
          },
        },
        -- Don't search hidden dot folders (e.g. .dist, .vscode) or node_modules in <leader>ff.
        -- NOTE: `exclude = { ".*" }` makes fd/rg exclude every file, so rely on
        -- `hidden = false` for dot folders and only explicitly exclude node_modules.
        hidden = false,
        ignored = false,
        exclude = { "node_modules", ".nodemodules" },
        -- If snacks falls back to `find`, paths come back as `./src/...`.
        -- Normalize that away and filter dot folders here too, so matching/opening stays sane.
        transform = function(item)
          local file = item.file or item.text or ""
          file = file:gsub("^%./", "")

          if file:match("^%.") or file:match("/%.") then
            return false
          end
          if file == "node_modules" or file:match("^node_modules/") or file:match("/node_modules/") then
            return false
          end
          if file == ".nodemodules" or file:match("^%.nodemodules/") or file:match("/%.nodemodules/") then
            return false
          end

          item.file = file
          item.text = file
          return item
        end,
        -- Hide the preview in <leader>ff.
        win = {
          input = {
            keys = {
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["<C-c>"] = { "close", mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["<Esc>"] = "close",
              ["<C-c>"] = "close",
            },
          },
        },
      })

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.sections = function(self)
        local win_width = self._size and self._size.width or vim.o.columns
        local win_height = self._size and self._size.height or vim.o.lines

        local width = math.max(1, math.min(60, win_width - 2))
        self.opts.width = width

        local header = width >= 60 and lazyvim_header or (width >= 24 and compact_header or (width >= 7 and "LazyVim" or "LV"))

        return {
          { header = header, align = "center", padding = win_height >= 14 and 2 or 0 },
          { section = "keys", gap = 1, padding = 1, enabled = width >= 38 and win_height >= 16 },
          { section = "startup", enabled = width >= 38 and win_height >= 10 },
        }
      end
    end,
  },
}
