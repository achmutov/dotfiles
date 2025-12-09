vim.api.nvim_create_autocmd("BufEnter", {
    -- make a group to be able to delete it later
    group = vim.api.nvim_create_augroup("NeoTreeInit", { clear = true }),
    callback = function()
        local f = vim.fn.expand("%:p")
        if vim.fn.isdirectory(f) ~= 0 then
            vim.cmd("Neotree current dir=" .. f)
            -- neo-tree is loaded now, delete the init autocmd
            vim.api.nvim_clear_autocmds({ group = "NeoTreeInit" })
        end
    end,
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
})

vim.keymap.set("n", "<leader>pv", ":Neotree toggle<CR>")
vim.keymap.set("n", "<leader>pd", ":Neotree document_symbols toggle<CR>")
