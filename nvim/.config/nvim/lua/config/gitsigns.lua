local signs = {
    add = { text = "+" },
    change = { text = "-" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
}

require("gitsigns").setup({
    numhl = true,
    culhl = true,
    signs = signs,
    signs_staged = signs,
    on_attach = function(buffnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = buffnr
            vim.keymap.set(mode, l, r, opts)
        end

        map("n", "<leader>hs", gs.stage_hunk)
        map("n", "<leader>hS", gs.stage_buffer)
        map("n", "<leader>hr", gs.reset_hunk)
        map("n", "<leader>hu", gs.undo_stage_hunk)
        map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end)
        map("n", "<leader>hu", gs.undo_stage_hunk)
        map("n", "<leader>hp", gs.preview_hunk)
        map("n", "<leader>td", gs.toggle_deleted)
        map("n", "<leader>tb", gs.blame)
    end,
})

vim.opt.signcolumn = "yes:2"

vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
vim.api.nvim_set_hl(0, "GitSignsAdd", { bg = "NONE", fg = "#b8bb26" })
vim.api.nvim_set_hl(0, "GitSignsChange", { bg = "NONE", fg = "#83a598" })
vim.api.nvim_set_hl(0, "GitSignsDelete", { bg = "NONE", fg = "#fb4934" })
