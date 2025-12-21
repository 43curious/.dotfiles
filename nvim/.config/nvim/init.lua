-- 1. Instalación de lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Opciones de Interfaz y Comportamiento
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.laststatus = 3
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.fillchars = { eob = " " } 
vim.opt.clipboard = "unnamedplus" -- Permite copiar/pegar con el sistema (Ctrl+C / Ctrl+V)

-- 3. Configuración de Plugins
require("lazy").setup({
    -- TEMA
    { 
        "rose-pine/neovim", 
        name = "rose-pine", 
        config = function()
            require('rose-pine').setup({ styles = { transparency = true } })
            vim.cmd("colorscheme rose-pine")
        end 
    },
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate'
    },

    {
        "mason-org/mason.nvim",
        opts = {}
    },

    -- GUÍAS DE INDENTACIÓN (Las rayitas)
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {
            indent = { char = "▏" }, -- Puedes cambiar el carácter por "|" si prefieres
            scope = { enabled = false }, -- Desactivamos el resaltado de scope por ahora para que sea simple
        },
    },

    {
        'saghen/blink.cmp',
        dependencies = { 'rafamadriz/friendly-snippets' },

        version = '1.*',
        opts = {
            -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
            -- 'super-tab' for mappings similar to vscode (tab to accept)
            -- 'enter' for enter to accept
            -- 'none' for no mappings
            keymap = { preset = 'default' },

            appearance = {
                nerd_font_variant = 'mono'
            },
            completion = { documentation = { auto_show = false } },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
            fuzzy = { implementation = "prefer_rust_with_warning" }
        },
        opts_extend = { "sources.default" }
    },
    -- TELESCOPE (Fuzzy Finder)
    {
        'nvim-telescope/telescope.nvim', 
        tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Buscar archivos" })
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Buscar texto (grep)" })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Ver buffers" })
        end
    },

    -- BARRA DE ESTADO
    { "nvim-lualine/lualine.nvim", opts = { options = { theme = 'rose-pine', globalstatus = true } } },

    -- EXPLORADOR
    { 
        "nvim-neo-tree/neo-tree.nvim", 
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        config = function()
            vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>')
        end
    },
})


-- 4. Transparencia Forzada
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
