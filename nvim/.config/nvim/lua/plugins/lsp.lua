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

        { "williamboman/mason-lspconfig.nvim" }, -- Optional

        -- Autocompletion
        -- {"hrsh7th/nvim-cmp"},     -- Required
        -- {"hrsh7th/cmp-nvim-lsp"}, -- Required

        { "Saghen/blink.cmp" },

        { "L3MON4D3/LuaSnip", build = "make install_jsregexp" }, -- Required
        { "j-hui/fidget.nvim" },
    },
    config = function()
        require("config.lsp")
    end,
}
