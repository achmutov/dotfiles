local utils = require("utils")

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
-- vim.o.colorcolumn = "80"

-- indent
utils.SetIndent(4)
vim.o.et = true
vim.o.si = true

-- persistence
vim.o.swf = false
vim.o.bk = false
vim.o.udir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.udf = true

-- search
vim.o.hls = true
vim.o.is = true

-- trail
vim.o.list = true
vim.opt.listchars:append({ trail = "◦" })

vim.o.ex = true

vim.keymap.set("v", "K", ":m '<-2<CR>gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv")

vim.keymap.set("n", "<M-n>", ":cnext<CR>")
vim.keymap.set("n", "<M-p>", ":cprev<CR>")

vim.keymap.set("n", "<M-b>", "<C-y>", { noremap = true })
vim.keymap.set("n", "<M-f>", "<C-E>", { noremap = true })

vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("x", "<leader>p", '"_dP')

vim.keymap.set("n", "<leader>sc", utils.toggleScrolloff(vim.o.so), { noremap = true })
vim.keymap.set("n", "<leader>xx", ":![ -x % ] && chmod -x % || chmod +x %<CR>", { silent = true })

vim.keymap.set("v", ">", ">gv", { noremap = true })
vim.keymap.set("v", "<", "<gv", { noremap = true })

vim.keymap.set("v", "<leader>\\", utils.toggleTrailingBackslash)
vim.keymap.set({ "n", "v" }, "<leader>t", utils.removeTrailingWhitespace)

vim.filetype.add({
    pattern = {
        ["docker-compose%.yml"] = "yaml.docker-compose",
        ["docker-compose%.yaml"] = "yaml.docker-compose",
        ["compose%.yml"] = "yaml.docker-compose",
        ["compose%.yaml"] = "yaml.docker-compose",
        [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
    },
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "javascript",
    callback = function()
        vim.bo.indentexpr = "v:lua.require'utils'.XGetJavascriptIndent"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "typescript",
    callback = function()
        vim.bo.indentexpr = "v:lua.require'utils'.XGetTypescriptIndent"
    end,
})

require("core")
