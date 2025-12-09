vim.g.mapleader = " "

-- Movements
vim.keymap.set("v", "K", ":m '<-2<CR>gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv")

-- Quickfix
vim.keymap.set("n", "<M-n>", ":cnext<CR>")
vim.keymap.set("n", "<M-p>", ":cprev<CR>")

-- By one line
vim.keymap.set("n", "<M-b>", "<C-y>", { noremap = true, silent = true })
vim.keymap.set("n", "<M-f>", "<C-E>", { noremap = true, silent = true })

-- Exit nvim terminal
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Yank buffers
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("x", "<leader>p", '"_dP')

-- Scroll
vim.keymap.set("n", "<leader>sc", function()
    if vim.o.scrolloff == 99999 then
        vim.opt.scrolloff = 8
    else
        vim.opt.scrolloff = 99999
    end
end, { noremap = true })

-- Quick Aliases
vim.keymap.set("n", "<leader>xx", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>mk", ":silent! make<CR>")
vim.keymap.set("n", "<leader>te", ":!")
vim.keymap.set("n", "<leader>c", ":!pre-commit run --all-files<CR>")
