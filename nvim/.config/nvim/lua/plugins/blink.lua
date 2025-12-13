return {
    "saghen/blink.cmp",
    dependencies = {
        "rafamadriz/friendly-snippets",
        "xzbdmw/colorful-menu.nvim",
        "onsails/lspkind.nvim",
    },
    version = "*",
    opts = {
        -- "default" for mappings similar to built-in completion
        -- "super-tab" for mappings similar to vscode (tab to accept, arrow keys to navigate)
        -- "enter" for mappings similar to "super-tab" but with "enter" to accept
        -- See the full "keymap" documentation for information on defining your own keymap.
        keymap = { preset = "default" },

        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },

        completion = {
            documentation = { auto_show = true },
            ghost_text = { enabled = true },
            menu = {
                draw = {
                    columns = { { "kind_icon" }, { "label", gap = 1 } },
                    components = {
                        kind_icon = {
                            text = function(ctx)
                                local icon = ctx.kind_icon
                                if vim.tbl_contains({ "Path" }, ctx.source_name) then
                                    local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                                    if dev_icon then
                                        icon = dev_icon
                                    end
                                else
                                    icon = require("lspkind").symbolic(ctx.kind, {
                                        mode = "symbol",
                                    })
                                end

                                return icon .. ctx.icon_gap
                            end,

                            -- Optionally, use the highlight groups from nvim-web-devicons
                            -- You can also add the same function for `kind.highlight` if you want to
                            -- keep the highlight groups in sync with the icons.
                            highlight = function(ctx)
                                local hl = ctx.kind_hl
                                if vim.tbl_contains({ "Path" }, ctx.source_name) then
                                    local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                                    if dev_icon then
                                        hl = dev_hl
                                    end
                                end
                                return hl
                            end,
                        },
                        label = {
                            text = function(ctx)
                                return require("colorful-menu").blink_components_text(ctx)
                            end,
                            highlight = function(ctx)
                                return require("colorful-menu").blink_components_highlight(ctx)
                            end,
                        },
                    },
                },
            },
        },

        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },

        signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
}
