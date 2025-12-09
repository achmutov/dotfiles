return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { -- Optional
            "williamboman/mason.nvim",
            run = function()
                ---@diagnostic disable-next-line: param-type-mismatch
                pcall(vim.cmd, "MasonUpdate")
            end,
        },

        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        {
            "folke/lazydev.nvim",
            ft = "lua",
            opts = {
                library = {
                    -- Load luvit types when the `vim.uv` word is found
                    { path = "luvit-meta/library", words = { "vim%.uv" } },
                },
            },
        },

        { "williamboman/mason-lspconfig.nvim" }, -- Optional

        -- Autocompletion
        -- {"hrsh7th/nvim-cmp"},     -- Required
        -- {"hrsh7th/cmp-nvim-lsp"}, -- Required

        { "Saghen/blink.cmp" },

        { "L3MON4D3/LuaSnip", build = "make install_jsregexp" }, -- Required
        { "SmiteshP/nvim-navic" },
        { "j-hui/fidget.nvim" },
    },
    config = function()
        require("config.lsp")
    end,
}
