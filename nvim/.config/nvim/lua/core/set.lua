-- Numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Tabs and indent --

function SetIndent(val)
    vim.opt.tabstop = val
    vim.opt.softtabstop = val
    vim.opt.shiftwidth = val
end

function SetIndentLocal(val)
    vim.opt_local.tabstop = val
    vim.opt_local.softtabstop = val
    vim.opt_local.shiftwidth = val
end

SetIndent(4)
vim.opt.expandtab = true
vim.opt.smartindent = true

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
