PREFERRED_FORMATTER = {}

local function lazy_setup()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
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

---@generic T: any
---@param fn fun(...): T
---@return  fun(): T
local function wrap(fn, ...)
  local vararg = { ... }
  return function()
    return fn(unpack(vararg))
  end
end

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
  vim.o.udir = vim.fn.stdpath("state") .. "/undodir"
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

  local so = vim.o.so
  vim.keymap.set("n", "<leader>sc", function()
    require("utils").toggleScrolloff(so)
  end)
  vim.keymap.set("n", "<leader>xx", ":![ -x % ] && chmod -x % || chmod +x %<CR>")

  vim.keymap.set("v", ">", ">gv")
  vim.keymap.set("v", "<", "<gv")

  vim.keymap.set("v", "<leader>\\", function()
    require("utils").toggleTrailingBackslash()
  end)
  vim.keymap.set({ "n", "v" }, "<leader>T", function()
    require("utils").removeTrailingWhitespace()
  end)
  vim.keymap.set("v", "<leader>S", function()
    require("utils").shlex_visual()
  end)

  vim.keymap.set("n", "<leader>li", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end)

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    return vim.lsp.buf.format({
      filter = function(client)
        local preferred_formatter = PREFERRED_FORMATTER[vim.bo.filetype]
        return preferred_formatter == nil or preferred_formatter == client.name
      end,
    })
  end)

  vim.keymap.set("n", "<C-u>", "<C-u>M")
  vim.keymap.set("n", "<C-d>", "<C-d>M")
  vim.keymap.set("n", "<C-f>", "<C-f>M")
  vim.keymap.set("n", "<C-b>", "<C-b>M")

  vim.keymap.set({ "n", "v" }, "<M-r>", ":restart<cr>")
end
core_keymaps()

vim.diagnostic.config({
  virtual_text = { current_line = false },
  virtual_lines = { current_line = true },
})

if vim.fn.has("nvim-0.12") == 1 then
  vim.lsp.document_color.enable(true, nil, { style = "virtual" })
  require("vim._core.ui2").enable()
end

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
local custom_treesitter_grammars = { "resc" }

local function autocommands()
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local path = vim.fn.expand("%:p") --[[@as string]]
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
      if require("nvim-treesitter.parsers")[name] or vim.list_contains(custom_treesitter_grammars, name) then
        require("nvim-treesitter").install(name)
        pcall(vim.treesitter.start)
      end
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
      ---@type nvim-ts.parsers
      local custom_parsers = {
        resc = {
          install_info = {
            url = "https://github.com/achmutov/tree-sitter-resc",
            revision = "c7a7a3f2716c0dbe305cbde566406faa279f7402",
            generate_from_json = false,
            path = "/home/doc/dev/achmutov/tree-sitter-resc",
            generate = true,
            queries = "queries",
          },
          tier = 2,
        },
      }
      for k, v in pairs(custom_parsers) do
        parsers[k] = v
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufNewFile", {
    nested = true,
    callback = function()
      require("source_pos").focus()
    end,
  })
end
autocommands()

local function plugins()
  ---@alias LazySpec_ (string|LazyPluginSpec)[]

  ---@alias Colorscheme
  ---| "gruvbox"
  ---| "koda"
  ---| "kanagawa:wave"
  ---| "kanagawa:dragon"
  ---| "zenbones:zenwritten"
  ---| "zenbones:kanagawabones"
  ---| "vesper"
  ---@type Colorscheme
  local colorscheme = "vesper"
  local colorscheme_transparent = true
  local colorscheme_deps = colorscheme_transparent and { "xiyaowong/transparent.nvim" } or {}
  local colorscheme_priority = 1000
  local function lazy_colorscheme(other)
    return colorscheme:match(other) == nil
  end

  ---@type LazySpec_
  local appearance = {
    "nvim-tree/nvim-web-devicons",
    { "xiyaowong/transparent.nvim", lazy = true },
    {
      "sainnhe/gruvbox-material",
      lazy = lazy_colorscheme("gruvbox"),
      priority = colorscheme_priority,
      dependencies = colorscheme_deps,
      config = function()
        vim.g.gruvbox_material_transparent_background = colorscheme_transparent
        vim.cmd.colo("gruvbox-material")
      end,
    },
    {
      "oskarnurm/koda.nvim",
      lazy = lazy_colorscheme("koda"),
      priority = colorscheme_priority,
      dependencies = colorscheme_deps,
      config = function()
        require("koda").setup({ transparent = colorscheme_transparent })
        vim.cmd.colo("koda")
      end,
    },
    {
      "rebelot/kanagawa.nvim",
      lazy = lazy_colorscheme("^kanagawa:"),
      priority = colorscheme_priority,
      dependencies = colorscheme_deps,
      config = function()
        ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
        require("kanagawa").setup({
          commentStyle = { italic = false },
          keywordStyle = { italic = false },
          transparent = colorscheme_transparent,
          ---@param colors KanagawaColors
          overrides = function(colors)
            local theme = colors.theme
            return { ["@variable.builtin"] = { fg = theme.syn.special2, italic = false } }
          end,
        })
        local colorscheme_name = colorscheme:gsub(":", "-")
        vim.cmd.colo(colorscheme_name)
      end,
    },
    { "rktjmp/lush.nvim", lazy = true },
    {
      "zenbones-theme/zenbones.nvim",
      lazy = lazy_colorscheme("^zenbones:"),
      priority = colorscheme_priority,
      dependencies = colorscheme_transparent and vim.list_extend({ "rktjmp/lush.nvim" }, colorscheme_deps) or nil,
      init = function()
        ---@diagnostic disable-next-line: unnecessary-if
        if colorscheme_transparent then
          vim.g.zenwritten = { transparent_background = 1 }
          vim.g.kanagawabones = { transparent_background = 1 }
        else
          vim.g.zenwritten_compat = 1
          vim.g.kanagawabones_compat = 1
        end
      end,
      config = function()
        vim.cmd.colo(colorscheme:sub(("zenbones:"):len() + 1))
      end,
    },
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      ---@module "ibl"
      ---@type ibl.config
      opts = {},
    },
    {
      "datsfilipe/vesper.nvim",
      lazy = lazy_colorscheme("vesper"),
      priority = colorscheme_priority,
      dependencies = colorscheme_deps,
      config = function()
        require("vesper").setup({
          transparent = colorscheme_transparent,
          italics = {
            comments = true,
            keywords = false,
            functions = false,
            strings = false,
            variables = false,
          },
          overrides = {
            NonText = { fg = require("vesper.colors").comment },
          },
        })
        vim.cmd.colo(colorscheme)
      end,
    },
    {
      "nvim-lualine/lualine.nvim",
      opts = {
        options = { theme = "gruvbox_dark" },
        sections = { lualine_c = { { "filename", path = 1 } } },
      },
    },
  }

  ---@type LazySpec_
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

  ---@type LazySpec_
  local navigation = {
    "Bekaboo/dropbar.nvim",
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
        "<leader>pt",
        "<leader>pz",
        "<leader>po",
        --
        { "<leader>w", mode = { "n", "v" } },
        --
        "<leader>vh",
        "<leader>vH",
        "gd",
        "gf",
        "gs",
        "gb",
        "<leader>r",
        "<leader>i",
        "<leader>d",
      } --[[@as (LazyKeysSpec[])]],
      cmd = "Telescope",
      config = function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        do
          --- @param esc boolean
          local function action_print_selected(esc)
            return function()
              local entry = action_state.get_selected_entry()
              local ordinal = entry[1] or entry.ordinal
              ---@diagnostic disable-next-line: unnecessary-if
              if ordinal then
                _ = esc and vim.api.nvim_input("<esc>")
              end
            end
          end

          require("telescope").setup({
            defaults = {
              mappings = {
                i = {
                  ["<M-9>"] = actions.cycle_history_next,
                  ["<M-0>"] = actions.cycle_history_prev,
                  ["<M-i>"] = action_print_selected(true),
                },
                n = {
                  ["<M-i>"] = action_print_selected(false),
                },
              },
              layout_config = {
                horizontal = {
                  height = 0.95,
                  width = 0.95,
                },
              },
            },
          })
        end
        require("telescope").load_extension("fzf")

        local builtin = require("telescope.builtin")

        do
          local find_files_opts
          if vim.fn.executable("rg") == 1 then
            find_files_opts = {
              hidden = true,
              find_command = vim.list_extend(
                { "rg", "--files", "--color", "never" }, -- telescope default
                { "-g", "!.git" }
              ),
            }
          end
          vim.keymap.set("n", "<leader>pf", wrap(builtin.find_files, find_files_opts))
        end
        vim.keymap.set("n", "<C-p>", function()
          if vim.bo.filetype ~= "TelescopePrompt" then
            _ = pcall(builtin.git_files) or vim.notify("No git repo found")
          end
        end)
        vim.keymap.set("n", "<leader>pw", function()
          builtin.grep_string({
            search = vim.fn.input("Grep > "),
            additional_args = { "--hidden" },
          })
        end)
        vim.keymap.set("n", "<leader>ps", function()
          builtin.live_grep({ hidden = true, additional_args = { "-g", "!.git" } })
        end)
        vim.keymap.set("n", "<leader>pr", builtin.resume)
        vim.keymap.set("n", "<leader>pt", builtin.treesitter)
        vim.keymap.set("n", "<leader>pz", builtin.current_buffer_fuzzy_find)
        vim.keymap.set("n", "<leader>po", builtin.oldfiles)
        vim.keymap.set("n", "<leader>w", builtin.grep_string)
        vim.keymap.set("v", "<leader>w", builtin.grep_string)
        vim.keymap.set("n", "<leader>vh", builtin.help_tags)
        vim.keymap.set("n", "<leader>vH", function()
          builtin.help_tags({
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection == nil then
                  return
                end
                actions.close(prompt_bufnr)
                vim.cmd("help " .. selection.value .. " | only")
              end)
              return true
            end,
          })
        end)
        vim.keymap.set("n", "gd", builtin.lsp_definitions)
        vim.keymap.set("n", "gf", builtin.lsp_type_definitions)
        vim.keymap.set("n", "gs", function()
          builtin.lsp_dynamic_workspace_symbols({
            fname_width = 0.7,
            symbol_width = 0.2,
            symbol_type_width = 0.1,
          })
        end)
        vim.keymap.set("n", "gb", function()
          builtin.lsp_document_symbols({
            symbol_width = 0.5,
            symbol_type_width = 0.5,
          })
        end)
        vim.keymap.set("n", "<leader>r", builtin.lsp_references)
        vim.keymap.set("n", "<leader>i", builtin.lsp_implementations)
        vim.keymap.set("n", "<leader>d", builtin.diagnostics)
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
        vim.keymap.set("n", "<leader>a", mark.add_file)
        vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
        vim.keymap.set("n", "<C-h>", wrap(ui.nav_file, 1))
        vim.keymap.set("n", "<C-t>", wrap(ui.nav_file, 2))
        vim.keymap.set("n", "<C-n>", wrap(ui.nav_file, 3))
        vim.keymap.set("n", "<C-s>", wrap(ui.nav_file, 4))
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
      },
      config = function()
        ---@diagnostic disable-next-line: missing-fields
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
        { "at", mode = { "x", "o" } },
        { "it", mode = { "x", "o" } },
        { "ac", mode = { "x", "o" } },
        { "ic", mode = { "x", "o" } },
        { "al", mode = { "x", "o" } },
        { "il", mode = { "x", "o" } },
        { "ab", mode = { "x", "o" } },
        { "ib", mode = { "x", "o" } },
        { "aa", mode = { "x", "o" } },
        { "ia", mode = { "x", "o" } },
        { "as", mode = { "x", "o" } },
      },
      config = function()
        local function select_textobject(query_string, query_group)
          return function()
            require("nvim-treesitter-textobjects.select").select_textobject(query_string, query_group)
          end
        end
        vim.keymap.set({ "x", "o" }, "am", select_textobject("@function.outer"))
        vim.keymap.set({ "x", "o" }, "im", select_textobject("@function.inner"))
        vim.keymap.set({ "x", "o" }, "at", select_textobject("@class.outer"))
        vim.keymap.set({ "x", "o" }, "it", select_textobject("@class.inner"))
        vim.keymap.set({ "x", "o" }, "ac", select_textobject("@conditional.outer"))
        vim.keymap.set({ "x", "o" }, "ic", select_textobject("@conditional.inner"))
        vim.keymap.set({ "x", "o" }, "al", select_textobject("@loop.outer"))
        vim.keymap.set({ "x", "o" }, "il", select_textobject("@loop.inner"))
        vim.keymap.set({ "x", "o" }, "ab", select_textobject("@block.outer"))
        vim.keymap.set({ "x", "o" }, "ib", select_textobject("@block.inner"))
        vim.keymap.set({ "x", "o" }, "aa", select_textobject("@parameter.outer"))
        vim.keymap.set({ "x", "o" }, "ia", select_textobject("@parameter.inner"))
      end,
    },
    {
      "folke/flash.nvim",
      event = "VeryLazy",
      ---@diagnostic disable-next-line: missing-fields
      ---@type Flash.Config
      opts = { modes = { char = { enabled = false } } },
      keys = {
        {
          "s",
          mode = { "n", "x", "o" },
          function()
            require("flash.commands").jump()
          end,
        },
        {
          "Y",
          mode = { "n", "x", "o" },
          function()
            require("flash.commands").treesitter()
          end,
        },
        {
          "R",
          mode = { "o", "x" },
          function()
            require("flash.commands").treesitter_search()
          end,
        },
        --
        {
          "r",
          mode = "o",
          function()
            require("flash.commands").remote()
          end,
        },
        {
          "<c-s>",
          mode = { "c" },
          function()
            require("flash.commands").toggle()
          end,
        },
      },
    },
  }

  ---@type LazySpec_
  local git = {
    "tpope/vim-fugitive",
    {
      "ruifm/gitlinker.nvim",
      keys = { { "<leader>gy", mode = { "n", "v" } } },
      config = function()
        require("gitlinker").setup({ mappings = "<leader>gy" })
      end,
    },
    {
      "esmuellert/codediff.nvim",
      keys = {
        { "<leader>gv", ":CodeDiff " },
        { "<leader>gc", "<cmd>CodeDiff<cr>" },
      },
      cmd = "CodeDiff",
      opts = {
        diff = { jump_to_first_change = false },
        explorer = { initial_focus = "modified" },
      },
    },
    {
      "https://github.com/NeogitOrg/neogit",
      dependencies = {
        "nvim-telescope/telescope.nvim",
        "esmuellert/codediff.nvim",
        "nvim-lua/plenary.nvim",
      },
      cmd = "Neogit",
      keys = {
        { "<leader>gs", "<cmd>Neogit kind=replace<cr>" },
      },
      config = function()
        local neogit = require("neogit")
        neogit.setup({
          treesitter_diff_highlight = true,
          disable_hint = true,
          disable_context_highlighting = true,
          graph_style = "unicode",
          process_spinner = true,
          highlight = { bg1 = "" },
          ---@diagnostic disable-next-line: assign-type-mismatch, missing-fields
          integrations = {
            telescope = true,
            codediff = true,
          },
        })
        vim.api.nvim_set_hl(0, "NeogitDiffDelete", { link = "NeogitDiffDeleteHighlight" })
        vim.api.nvim_set_hl(0, "NeogitDiffAdd", { link = "NeogitDiffAddHighlight" })
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

  ---@type LazySpec_
  local misc = {
    {
      "RRethy/vim-illuminate",
      keys = {
        {
          "<leader>o",
          function()
            local illuminate = require("illuminate")
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

  ---@type LazySpec_
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
        ---@diagnostic disable: missing-fields, param-type-mismatch
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
                        icon = require("lspkind").symbolic(ctx.kind)
                      end
                      return icon .. ctx.icon_gap
                    end,
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
              direction_priority = function()
                local ctx = require("blink.cmp").get_context()
                local item = require("blink.cmp").get_selected_item()
                if ctx == nil or item == nil then
                  return { "s", "n" }
                end

                local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
                local is_multi_line = item_text:find("\n") ~= nil

                if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
                  vim.g.blink_cmp_upwards_ctx_id = ctx.id
                  return { "n", "s" }
                end
                return { "s", "n" }
              end,
            },
          },
          sources = { default = { "lsp", "path", "snippets", "buffer" } },
          signature = { enabled = true },
        })
        ---@diagnostic enable: missing-fields, param-type-mismatch
      end,
    },
    {
      "L3MON4D3/LuaSnip",
      build = "make install_jsregexp",
    },
  }

  ---@type LazySpec_
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
        vim.lsp.enable(require("config").lsp)
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
        ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
        require("mason").setup({ PATH = "skip" })
      end,
    },
    {
      "hedyhli/outline.nvim",
      lazy = true,
      cmd = { "Outline", "OutlineOpen" },
      keys = { { "<leader>pd", "<cmd>Outline<CR>" } },
      opts = {
        outline_window = { position = "left" },
        outline_items = { show_symbol_lineno = true },
        symbols = { icon_source = "lspkind" },
        keymaps = { close = {} },
      },
    },
  }

  ---@type LazySpec_
  local lang = {
    {
      "selimacerbas/markdown-preview.nvim",
      dependencies = { "selimacerbas/live-server.nvim" },
      keys = { { "<leader>M", "<cmd>MarkdownPreview<cr>" } },
      opts = {
        hooks = {
          on_start = function(url)
            print("Preview started: " .. url)
          end,
          on_stop = function()
            print("Preview stopped")
          end,
        },
      },
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
    {
      "https://github.com/gentoo/gentoo-syntax",
      ft = { "gentoo-*", "ebuild" },
    },
  }

  ---@type LazySpec_
  local debugging = {
    {
      "mfussenegger/nvim-dap",
      dependencies = {
        "nvim-neotest/nvim-nio",
        "rcarriga/nvim-dap-ui",
        "theHamsta/nvim-dap-virtual-text",
        "nvim-telescope/telescope.nvim",
      },
      lazy = true,
      keys = {
        "<leader><F1>",
        "<leader>b",
      },
      config = function()
        local telescope_dap = require("telescope").load_extension("dap")
        local dap = require("dap")
        local ui = require("dapui")
        local dapfile = ".nvim-dap.lua"
        vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
        vim.keymap.set("n", "<leader>B", telescope_dap.breakpoints)
        vim.keymap.set("n", "<leader>?", function()
          ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
          ui.eval(nil, { enter = true })
        end)
        vim.keymap.set("n", "<leader><F1>", dap.continue)
        vim.keymap.set("n", "<leader><F2>", dap.step_into)
        vim.keymap.set("n", "<leader><F3>", dap.step_over)
        vim.keymap.set("n", "<leader><F4>", dap.step_out)
        vim.keymap.set("n", "<leader><F5>", dap.step_back)
        vim.keymap.set("n", "<leader><F10>", function()
          ui.toggle({ reset = true })
        end)
        vim.keymap.set("n", "<leader><F11>", dap.terminate)
        vim.keymap.set("n", "<leader><F12>", dap.restart)
        vim.keymap.set("n", "<leader>9", dap.up)
        vim.keymap.set("n", "<leader>0", dap.down)
        vim.keymap.set("n", "<leader>R", function()
          _ = pcall(vim.cmd.so, dapfile) and vim.notify("Reloaded " .. dapfile)
        end)
        vim.keymap.set("n", "<leader>F", telescope_dap.frames)

        dap.listeners.before.attach.dapui_config = ui.open
        dap.listeners.before.launch.dapui_config = ui.open
        dap.listeners.before.event_terminated.dapui_config = wrap(ui.close)
        dap.listeners.before.event_exited.dapui_config = wrap(ui.close)

        require("achmutov.dap-adapters").setup()
        _ = pcall(vim.cmd.so, dapfile) and vim.notify("Imported " .. dapfile)
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
      keys = { { "<leader>m", "<cmd>OtterActivate<cr>" } },
    },
  }

  ---@diagnostic disable-next-line: param-type-mismatch
  require("lazy").setup({
    spec = { appearance, core, navigation, git, misc, cmp, lsp, lang, debugging },
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
    require("nvim-treesitter").install(require("achmutov.treesitter")):wait()
  end, {})

  vim.api.nvim_create_user_command("MasonInstallAll", function()
    local installed_packages = require("mason-registry").get_installed_package_names()
    local to_install = vim.tbl_filter(function(p)
      return not vim.tbl_contains(installed_packages, p)
    end, require("config").mason)
    require("mason.api.command").MasonInstall(to_install)
  end, {})

  vim.api.nvim_create_user_command("Shlex", function(opts)
    require("utils").shlex_cmd(opts)
  end, { nargs = "*", range = true })
end
user_commands()
