vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local f = vim.fn.expand("%:p")
        if vim.fn.isdirectory(f) ~= 0 then
            local git = require("neogit.lib.git")
            local cmd
            if git.cli.is_inside_worktree(f) then
                cmd = "Neogit"
            else
                cmd = "Neotree current dir=" .. f
            end
            vim.cmd(cmd)
        end
    end,
    once = true,
})

require("neo-tree").setup({
    sources = {
        "filesystem",
        "buffers",
        "git_status",
        "document_symbols",
    },
    filesystem = {
        hijack_netrw_behavior = "open_current",
    },
    window = {
        mappings = {
            ["J"] = "toggle_node",
            ["P"] = { "toggle_preview", config = { use_float = false } },
            ["o"] = "system_open",
            ["Z"] = "expand_all_nodes",
            ["x"] = "expand_all_sibling_nodes",
        },
    },
    commands = {
        system_open = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            -- Linux: open file in default application
            vim.fn.jobstart({ "xdg-open", path }, { detach = true })
        end,
    },
    document_symbols = {
        client_filters = {
            ignore = { "pylsp" },
        },
    },
    log_level = "error",
})

vim.keymap.set("n", "<leader>pv", ":Neotree toggle<CR>")
vim.keymap.set("n", "<leader>pd", ":Neotree document_symbols toggle<CR>")

vim.api.nvim_set_hl(0, require("neo-tree.ui.highlights").PREVIEW, { link = "Visual" })
