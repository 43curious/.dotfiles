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
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.scroll = { enabled = false }

      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
        -- Close the explorer after opening a file with <Enter>.
        jump = { close = true },
        layout = {
          preview = false,
          layout = {
            backdrop = false,
            width = 0,
            height = 0,
            border = "none",
            box = "vertical",
            { win = "input", height = 1, border = "bottom", title = "{title} {live} {flags}" },
            { win = "list", border = "none" },
          },
        },
      })

      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
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
        layout = { preview = false },
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
