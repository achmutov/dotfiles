local utils = require("utils")
local config = require("config")

local function lazy_setup()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
            vim.api.nvim_echo({
                { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
                { out, "WarningMsg" },
                { "\nPress any key to exit..." },
            }, true, {})
            vim.fn.getchar()
            os.exit(1)
        end
    end
    vim.opt.rtp:prepend(lazypath)
end
lazy_setup()

local function core_opts()
    vim.g.mapleader = " "

    -- numbers
    vim.o.nu = true
    vim.o.rnu = true

    -- appearance
    vim.o.gcr = ""
    vim.o.winborder = "bold"
    vim.o.tgc = true
    vim.o.stal = 0
    vim.o.so = 8
    vim.o.scl = "auto:2"
    vim.o.fen = false

    -- indent
    vim.o.ts = 4
    vim.o.sts = -1
    vim.o.sw = 0
    vim.o.et = true
    vim.o.si = true

    -- persistence
    vim.o.swf = false
    vim.o.bk = false
    vim.o.udir = vim.fn.expand("~/.vim/undodir")
    vim.o.udf = true

    -- search
    vim.o.hls = true
    vim.o.is = true

    -- trail
    vim.o.list = true
    vim.opt.listchars:append({ trail = "◦" })

    vim.o.ex = true
end
core_opts()

local function core_keymaps()
    vim.keymap.set("v", "K", ":m '<-2<CR>gv")
    vim.keymap.set("v", "J", ":m '>+1<CR>gv")

    vim.keymap.set("n", "<M-n>", ":cnext<CR>")
    vim.keymap.set("n", "<M-p>", ":cprev<CR>")

    vim.keymap.set("n", "<M-b>", "<C-y>")
    vim.keymap.set("n", "<M-f>", "<C-E>")

    vim.keymap.set("v", "<leader>y", '"+y')
    vim.keymap.set("x", "<leader>p", '"_dP')

    vim.keymap.set("n", "<leader>sc", utils.toggleScrolloff(vim.o.so))
    vim.keymap.set("n", "<leader>xx", ":![ -x % ] && chmod -x % || chmod +x %<CR>")

    vim.keymap.set("v", ">", ">gv")
    vim.keymap.set("v", "<", "<gv")

    vim.keymap.set("v", "<leader>\\", utils.toggleTrailingBackslash)
    vim.keymap.set({ "n", "v" }, "<leader>t", utils.removeTrailingWhitespace)

    vim.keymap.set("n", "<leader>li", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end)

    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

    vim.keymap.set("n", "<C-u>", "<C-u>M")
    vim.keymap.set("n", "<C-d>", "<C-d>M")
    vim.keymap.set("n", "<C-f>", "<C-d>M")
    vim.keymap.set("n", "<C-b>", "<C-d>M")

    vim.keymap.set({ "n", "v" }, "<M-r>", ":restart<cr>")
end
core_keymaps()

vim.diagnostic.config({
    virtual_text = { current_line = false },
    virtual_lines = { current_line = true },
})

vim.filetype.add({
    pattern = {
        ["docker-compose%.ya?ml"] = "yaml.docker-compose",
        [".*%.resc"] = "resc",
        -- [".*%.repl"] = "repl",
        ["compose%.ya?ml"] = "yaml.docker-compose",
        [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
    },
})
local custom_ft_to_native = {
    ["yaml.docker-compose"] = "yaml",
    ["yaml.github"] = "yaml",
}

local function autocommands()
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            local path = vim.fn.expand("%:p")
            if vim.fn.isdirectory(path) ~= 0 then
                if require("neogit.lib.git.cli").is_inside_worktree(path) then
                    vim.cmd("Neogit cwd=" .. path)
                else
                    vim.cmd("Neotree current dir=" .. path)
                end
            end
        end,
        once = true,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "javascript",
        callback = function()
            vim.bo.indentexpr = "v:lua.require'utils'.XGetJavascriptIndent()"
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "typescript",
        callback = function()
            vim.bo.indentexpr = "v:lua.require'utils'.XGetTypescriptIndent()"
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
            local result = vim.uv.fs_stat(ev.file)
            if result == nil or result.size > 1000 * 1024 then
                return
            end
            local name = custom_ft_to_native[ev.match] or ev.match
            require("nvim-treesitter").install(name)
            pcall(vim.treesitter.start)
        end,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
            local opts = { buffer = event.buf }
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
            vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>c", vim.lsp.buf.code_action, opts)
        end,
    })
    --
    vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
            local parsers = require("nvim-treesitter.parsers")
            parsers.resc = {
                install_info = {
                    url = "https://github.com/achmutov/tree-sitter-resc",
                    revision = "c7a7a3f2716c0dbe305cbde566406faa279f7402",
                    generate_from_json = false,
                    path = "/home/doc/dev/achmutov/tree-sitter-resc",
                    generate = true,
                    queries = "queries",
                },
                tier = 2,
            }
        end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "photon",
        callback = function()
            vim.api.nvim_set_hl(0, "NonText", {})
            vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1b3027", fg = "#87af87" })
            vim.api.nvim_set_hl(0, "DiffChange", { bg = "#242D30" })
            vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#301F23" })
            vim.api.nvim_set_hl(0, "GitSignsAdd", { bg = "NONE", fg = "#b8bb26" })
            vim.api.nvim_set_hl(0, "GitSignsChange", { bg = "NONE", fg = "#83a598" })
            vim.api.nvim_set_hl(0, "GitSignsDelete", { bg = "NONE", fg = "#fb4934" })
        end,
    })
end
autocommands()

local function plugins()
    ---@alias Colorscheme
    ---| "gruvbox"
    ---| "koda"
    ---| "kanagawa"
    ---| "photon"
    ---| "zenbones"
    ---@type Colorscheme
    local colorscheme = "zenbones"

    ---@type LazySpec
    local appearance = {
        "nvim-tree/nvim-web-devicons",
        {
            "sainnhe/gruvbox-material",
            dependencies = { "xiyaowong/transparent.nvim" },
            lazy = (colorscheme ~= "gruvbox"),
            config = function()
                vim.g.gruvbox_material_transparent_background = 1
                vim.cmd.colo("gruvbox-material")
            end,
        },
        {
            "oskarnurm/koda.nvim",
            lazy = (colorscheme ~= "koda"),
            dependencies = { "xiyaowong/transparent.nvim" },
            config = function()
                vim.cmd.colo("koda")
            end,
        },
        {
            "rebelot/kanagawa.nvim",
            lazy = (colorscheme ~= "kanagawa"),
            config = function()
                require("kanagawa").setup({
                    commentStyle = { italic = false },
                    keywordStyle = { italic = false },
                    ---@param colors KanagawaColors
                    overrides = function(colors)
                        local theme = colors.theme
                        return { ["@variable.builtin"] = { fg = theme.syn.special2, italic = false } }
                    end,
                })
                vim.cmd.colo("kanagawa-dragon")
            end,
        },
        {
            "axvr/photon.vim",
            lazy = (colorscheme ~= "photon"),
            config = function()
                -- TODO:
                -- * floating windows
                -- * indent-blankline
                -- * blink
                -- * virtual text
                vim.cmd.colo("photon")
            end,
        },
        {
            "zenbones-theme/zenbones.nvim",
            lazy = (colorscheme ~= "zenbones"),
            init = function()
                vim.g.zenwritten_compat = 1
            end,
            config = function()
                vim.cmd.colo("zenwritten")
            end,
        },
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            opts = {},
        },
        {
            "nvim-lualine/lualine.nvim",
            config = function()
                require("lualine").setup({
                    options = { theme = "gruvbox_dark" },
                    sections = { lualine_c = { { "filename", path = 1 } } },
                })
            end,
        },
    }

    ---@type LazySpec
    local core = {
        "Pocco81/auto-save.nvim",
        {
            "kylechui/nvim-surround",
            version = "^4.0.0",
        },
        {
            "windwp/nvim-autopairs",
            event = "InsertEnter",
            config = true,
        },
        {
            "mbbill/undotree",
            keys = {
                { "<leader>u", "<cmd>UndotreeToggle<cr>" },
            },
        },
        {
            "nvim-treesitter/nvim-treesitter",
            lazy = true,
            build = ":TSUpdate",
        },
    }

    ---@type LazySpec
    local navigation = {
        {
            "Bekaboo/dropbar.nvim",
        },
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            lazy = true,
            build = "make",
        },
        {
            "nvim-telescope/telescope.nvim",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-telescope/telescope-fzf-native.nvim",
            },
            keys = {
                "<leader>pf",
                --
                "<C-p>",
                "<leader>pw",
                "<leader>ps",
                "<leader>pr",
                --
                { "<leader>w", mode = { "n", "v" } },
                --
                "<leader>vh",
                "gd",
                "gf",
                "gs",
                "<leader>r",
                "<leader>i",
                "<leader>d",
            },
            cmd = "Telescope",
            config = function()
                local actions = require("telescope.actions")
                local builtin = require("telescope.builtin")
                require("telescope").setup({
                    defaults = {
                        mappings = {
                            i = {
                                ["<M-9>"] = actions.cycle_history_next,
                                ["<M-0>"] = actions.cycle_history_prev,
                            },
                        },
                    },
                })
                require("telescope").load_extension("fzf")
                vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
                --
                vim.keymap.set("n", "<C-p>", function()
                    pcall(builtin.git_files)
                end, {})
                vim.keymap.set("n", "<leader>pw", function()
                    builtin.grep_string({ search = vim.fn.input("Grep > ") })
                end)
                vim.keymap.set("n", "<leader>ps", builtin.live_grep, {})
                vim.keymap.set("n", "<leader>pr", builtin.resume, {})
                --
                vim.keymap.set("n", "<leader>w", builtin.grep_string, {})
                vim.keymap.set("v", "<leader>w", builtin.grep_string, {})
                --
                vim.keymap.set("n", "<leader>vh", builtin.help_tags, {})
                vim.keymap.set("n", "gd", builtin.lsp_definitions, {})
                vim.keymap.set("n", "gf", builtin.lsp_type_definitions, {})
                vim.keymap.set("n", "gs", builtin.lsp_dynamic_workspace_symbols, {})
                vim.keymap.set("n", "<leader>r", builtin.lsp_references, {})
                vim.keymap.set("n", "<leader>i", builtin.lsp_implementations, {})
                vim.keymap.set("n", "<leader>d", builtin.diagnostics, {})
            end,
        },
        {
            "theprimeagen/harpoon",
            keys = {
                "<leader>a",
                "<C-e>",
                "<C-h>",
                "<C-t>",
                "<C-n>",
                "<C-s>",
            },
            config = function()
                local mark = require("harpoon.mark")
                local ui = require("harpoon.ui")
                local function nav_file(id)
                    return function()
                        ui.nav_file(id)
                    end
                end
                vim.keymap.set("n", "<leader>a", mark.add_file)
                vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
                vim.keymap.set("n", "<C-h>", nav_file(1))
                vim.keymap.set("n", "<C-t>", nav_file(2))
                vim.keymap.set("n", "<C-n>", nav_file(3))
                vim.keymap.set("n", "<C-s>", nav_file(4))
            end,
        },
        {
            "achmutov/neo-tree.nvim",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-tree/nvim-web-devicons",
                "MunifTanjim/nui.nvim",
            },
            cmd = "Neotree",
            keys = {
                { "<leader>pv", ":Neotree toggle<CR>" },
                { "<leader>pd", ":Neotree document_symbols toggle<CR>" },
            },
            config = function()
                require("neo-tree").setup({
                    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
                    filesystem = { hijack_netrw_behavior = "open_current" },
                    window = {
                        mappings = {
                            ["J"] = "toggle_node",
                            ["P"] = { "toggle_preview", config = { use_float = false } },
                            ["o"] = "system_open",
                            ["Z"] = "expand_all_nodes",
                            ["X"] = "expand_all_sibling_nodes",
                        },
                    },
                    commands = {
                        system_open = function(state)
                            local node = state.tree:get_node() ---@diagnostic disable-line: undefined-field
                            local path = node:get_id()
                            vim.fn.jobstart({ "xdg-open", path }, { detach = true })
                        end,
                    },
                    log_level = "error",
                })
                vim.api.nvim_set_hl(0, require("neo-tree.ui.highlights").PREVIEW, { link = "Visual" })
            end,
        },
        {
            "nvim-treesitter/nvim-treesitter-textobjects",
            branch = "main",
            init = function()
                vim.g.no_plugin_maps = true
            end,
            keys = {
                { "am", mode = { "x", "o" } },
                { "im", mode = { "x", "o" } },
                { "ac", mode = { "x", "o" } },
                { "ic", mode = { "x", "o" } },
                { "as", mode = { "x", "o" } },
            },
            config = function()
                local function select_textobject(query_string, query_group)
                    return function()
                        require("nvim-treesitter-textobjects.select").select_textobject(query_string, query_group)
                    end
                end
                vim.keymap.set({ "x", "o" }, "am", select_textobject("@function.outer", "textobjects"))
                vim.keymap.set({ "x", "o" }, "im", select_textobject("@function.inner", "textobjects"))
                vim.keymap.set({ "x", "o" }, "ac", select_textobject("@class.outer", "textobjects"))
                vim.keymap.set({ "x", "o" }, "ic", select_textobject("@class.inner", "textobjects"))
                vim.keymap.set({ "x", "o" }, "as", select_textobject("@local.scope", "locals"))
            end,
        },
        {
            "folke/flash.nvim",
            event = "VeryLazy",
            ---@type Flash.Config
            opts = { modes = { char = { enabled = false } } },
            keys = {
                {
                    "s",
                    mode = { "n", "x", "o" },
                    function()
                        require("flash").jump()
                    end,
                },
                {
                    "S",
                    mode = { "n", "x", "o" },
                    function()
                        require("flash").treesitter()
                    end,
                },
                {
                    "R",
                    mode = { "o", "x" },
                    function()
                        require("flash").treesitter_search()
                    end,
                },
                --
                {
                    "r",
                    mode = "o",
                    function()
                        require("flash").remote()
                    end,
                },
                {
                    "<c-s>",
                    mode = { "c" },
                    function()
                        require("flash").toggle()
                    end,
                },
            },
        },
    }

    ---@type LazySpec
    local git = {
        {
            "tpope/vim-fugitive",
        },
        {
            "ruifm/gitlinker.nvim",
            keys = { { "<leader>gy", mode = { "n", "v" } } },
            config = function()
                require("gitlinker").setup({ mappings = "<leader>gy" })
            end,
        },
        {
            "sindrets/diffview.nvim",
            keys = {
                { "<leader>gv", "<cmd>DiffviewOpen<cr>" },
                { "<leader>gc", "<cmd>DiffviewClose<cr>" },
            },
            cmd = "DiffviewOpen",
        },
        {
            "barrettruth/diffs.nvim",
            -- lazy = true,
            -- cmd = { "Gdiff", "Gvdiff", "Ghdiff" },
            init = function()
                vim.g.diffs = {
                    integrations = {
                        neogit = true,
                    },
                }
            end,
        },
        {
            "https://github.com/NeogitOrg/neogit",
            dependencies = {
                "nvim-telescope/telescope.nvim",
                "sindrets/diffview.nvim",
                "nvim-lua/plenary.nvim",
                "barrettruth/diffs.nvim",
            },
            cmd = "Neogit",
            keys = {
                { "<leader>gs", "<cmd>Neogit kind=replace<cr>" },
            },
            config = function()
                local neogit = require("neogit")
                neogit.setup({
                    disable_hint = true,
                    disable_context_highlighting = true,
                    graph_style = "unicode",
                    process_spinner = true,
                    highlight = { bg1 = "" },
                    integrations = { telescope = true, diffview = true },
                })
            end,
        },
        {
            "lewis6991/gitsigns.nvim",
            config = function()
                local gs = require("gitsigns")
                gs.setup({
                    numhl = true,
                    on_attach = function(buffnr)
                        local opts = { buffer = buffnr }
                        vim.keymap.set("n", "<leader>hs", gs.stage_hunk, opts)
                        vim.keymap.set("n", "<leader>hS", gs.stage_buffer, opts)
                        vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts)
                        vim.keymap.set("v", "<leader>hs", function()
                            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                        end, opts)
                        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts)
                        vim.keymap.set("n", "<leader>tb", gs.blame, opts)
                    end,
                })
                vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "GitSignsAdd", { bg = "NONE", fg = "#b8bb26" })
                vim.api.nvim_set_hl(0, "GitSignsChange", { bg = "NONE", fg = "#83a598" })
                vim.api.nvim_set_hl(0, "GitSignsDelete", { bg = "NONE", fg = "#fb4934" })
            end,
        },
    }

    ---@type LazySpec
    local misc = {
        {
            "RRethy/vim-illuminate",
            keys = {
                {
                    "<leader>o",
                    function()
                        local illuminate = package.loaded.illuminate
                        local engine = require("illuminate.engine")
                        if illuminate.is_paused() then
                            illuminate.resume()
                        else
                            illuminate.toggle_freeze_buf()
                            engine.refresh_references()
                        end
                    end,
                },
            },
            config = function()
                local illuminate = require("illuminate")
                illuminate.configure({ delay = 0 })
                illuminate.pause()
                vim.keymap.set({ "n", "i" }, "<C-l>", function()
                    illuminate.unfreeze_buf()
                    illuminate.pause()
                    vim.cmd("noh")
                end)
                vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#ffffff", fg = "#000000" })
                vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = "#83a598", fg = "#ffffff" })
                vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "#fb4934", fg = "#ffffff" })
            end,
        },
        {
            "danymat/neogen",
            config = function()
                require("neogen").setup({
                    languages = {
                        python = {
                            template = {
                                annotation_convention = "google_docstrings",
                            },
                        },
                    },
                })
            end,
            cmd = "Neogen",
        },
    }
    vim.keymap.set("n", "<leader>ng", vim.cmd.Neogen)

    ---@type LazySpec
    local cmp = {
        {
            "saghen/blink.cmp",
            version = "1.*",
            dependencies = {
                "rafamadriz/friendly-snippets",
                "xzbdmw/colorful-menu.nvim",
                "onsails/lspkind.nvim",
                "L3MON4D3/LuaSnip",
            },
            config = function()
                require("blink-cmp").setup({
                    keymap = {
                        preset = "default",
                        ["<C-space>"] = { "show", "select_and_accept", "fallback" },
                    },
                    completion = {
                        list = { selection = { auto_insert = false } },
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
                                                icon = dev_icon or icon
                                            else
                                                icon = require("lspkind").symbolic(ctx.kind, { mode = "symbol" })
                                            end
                                            return icon .. ctx.icon_gap
                                        end,
                                        highlight = function(ctx)
                                            local hl = ctx.kind_hl
                                            if vim.tbl_contains({ "Path" }, ctx.source_name) then
                                                local dev_icon, dev_hl =
                                                    require("nvim-web-devicons").get_icon(ctx.label)
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
                    sources = { default = { "lsp", "path", "snippets", "buffer" } },
                    signature = { enabled = true },
                })
            end,
        },
        {
            "L3MON4D3/LuaSnip",
            build = "make install_jsregexp",
        },
    }

    ---@type LazySpec
    local lsp = {
        {
            "j-hui/fidget.nvim",
            event = "LspAttach",
            opts = {
                notification = {
                    window = { winblend = 0 },
                    override_vim_notify = true,
                },
            },
        },
        {
            "neovim/nvim-lspconfig",
            event = "VeryLazy",
            config = function()
                vim.env.PATH = vim.env.PATH .. ":" .. (vim.fn.stdpath("data") .. "/mason/bin")
                vim.lsp.enable(config.lsp)
            end,
        },
        {
            "mason-org/mason.nvim",
            cmd = {
                "Mason",
                "MasonUpdate",
                "MasonInstallAll",
            },
            config = function()
                require("mason").setup({
                    PATH = "skip",
                })
            end,
        },
    }

    ---@type LazySpec
    local lang = {
        {
            "iamcco/markdown-preview.nvim",
            build = "cd app && npx yarn --frozen-lockfile",
            init = function()
                vim.g.mkdp_filetypes = { "markdown" }
                vim.g.mkdp_auto_close = 0
                vim.g.mkdp_preview_options = {
                    disable_sync_scroll = 1,
                }
            end,
            ft = "markdown",
        },
        {
            "folke/lazydev.nvim",
            opts = {
                library = {
                    { path = "luvit-meta/library", words = { "vim%.uv" } },
                },
            },
            ft = "lua",
        },
        {
            "lervag/vimtex",
            config = function()
                vim.g.vimtex_view_general_viewer = "zathura"
                vim.g.vimtex_view_method = "zathura"
                vim.keymap.set("n", "<leader>lc", ":VimtexCompile<CR>")
                vim.keymap.set("n", "<leader>lv", ":VimtexView<CR>")
            end,
            ft = "tex",
        },
    }

    ---@type LazySpec
    local debugging = {
        {
            "mfussenegger/nvim-dap",
            dependencies = {
                "nvim-neotest/nvim-nio",
                "rcarriga/nvim-dap-ui",
                "theHamsta/nvim-dap-virtual-text",
            },
            lazy = true,
            keys = {
                "<leader><F1>",
                "<leader>b",
            },
            config = function()
                local dap = require("dap")
                local ui = require("dapui")
                vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
                vim.keymap.set("n", "<leader>?", function()
                    ui.eval(nil, { enter = true }) ---@diagnostic disable-line: missing-fields
                end)
                vim.keymap.set("n", "<leader><F1>", dap.continue)
                vim.keymap.set("n", "<leader><F2>", dap.step_into)
                vim.keymap.set("n", "<leader><F3>", dap.step_over)
                vim.keymap.set("n", "<leader><F4>", dap.step_out)
                vim.keymap.set("n", "<leader><F5>", dap.step_back)
                vim.keymap.set("n", "<leader><F11>", dap.terminate)
                vim.keymap.set("n", "<leader><F12>", dap.restart)
                vim.keymap.set("n", "<leader>9", dap.up)
                vim.keymap.set("n", "<leader>0", dap.down)

                dap.adapters.python = {
                    type = "executable",
                    command = "debugpy-adapter",
                }

                dap.adapters.codelldb = {
                    type = "executable",
                    command = "codelldb",
                }

                dap.adapters.lldb = {
                    type = "executable",
                    command = "lldb-dap",
                }

                dap.adapters.gdb = {
                    type = "executable",
                    command = "gdb",
                    args = { "--quiet", "--interpreter=dap" },
                }

                dap.listeners.before.attach.dapui_config = ui.open
                dap.listeners.before.launch.dapui_config = ui.open
                dap.listeners.before.event_terminated.dapui_config = ui.close
                dap.listeners.before.event_exited.dapui_config = ui.close
            end,
        },
        {
            "rcarriga/nvim-dap-ui",
            lazy = true,
            config = true,
        },
        {
            "theHamsta/nvim-dap-virtual-text",
            lazy = true,
            config = true,
        },
        {
            "jmbuhr/otter.nvim",
            keys = { "<leader>m" },
            config = function()
                vim.keymap.set("n", "<leader>m", function()
                    require("otter").activate()
                end)
            end,
        },
    }

    local spec = {}
    for _, spec_part in ipairs({ appearance, core, navigation, git, misc, cmp, lsp, lang, debugging }) do
        assert(type(spec_part) ~= "string")
        for _, p in ipairs(spec_part) do
            table.insert(spec, p)
        end
    end

    require("lazy").setup({
        spec = spec,
        change_detection = { notify = false },
        performance = {
            rtp = {
                disabled_plugins = {
                    "netrwPlugin",
                    "tutor",
                },
            },
        },
    })
end
plugins()

local function user_commands()
    vim.api.nvim_create_user_command("TSInstallAll", function()
        require("nvim-treesitter").install(config.treesitter):wait()
    end, {})

    vim.api.nvim_create_user_command("MasonInstallAll", function()
        local installed_packages = require("mason-registry").get_installed_package_names()
        local to_install = vim.tbl_filter(function(p)
            return not vim.tbl_contains(installed_packages, p)
        end, config.mason)
        require("mason.api.command").MasonInstall(to_install)
    end, {})
end
user_commands()
