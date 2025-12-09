-- Numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Tabs and indent --
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Two tab indentation
local two_space_filetypes = { "r", "javascript", "ts", "typescriptreact", "html", "css", "rmd", "nix" }
local indent_group = vim.api.nvim_create_augroup("IndentationSettings", { clear = true })
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = indent_group,
    pattern = two_space_filetypes,
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
    end,
})

-- Persistence
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Search
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Colors
vim.opt.termguicolors = true
-- vim.opt.colorcolumn = "80"

-- Cursor
vim.opt.guicursor = ""

vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")

-- Disable tab buffers
vim.opt.showtabline = 0

-- Trailing whitespaces
vim.opt.list = true
vim.opt.listchars:append({ trail = "◦" })

---@diagnostic disable-next-line: lowercase-global
function trail()
    vim.api.nvim_buf_call(0, function()
        vim.cmd("%s/ *$//")
        vim.cmd("noh")
    end)
end

vim.filetype.add({
    pattern = {
        ["docker-compose%.yml"] = "yaml.docker-compose",
        ["docker-compose%.yaml"] = "yaml.docker-compose",
        ["compose%.yml"] = "yaml.docker-compose",
        ["compose%.yaml"] = "yaml.docker-compose",
    },
})

vim.filetype.add({
    pattern = {
        [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
    },
})

vim.opt.exrc = true
