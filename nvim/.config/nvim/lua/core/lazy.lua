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

local function isNixos()
    local file = io.open("/etc/os-release")
    if not file then
        return false
    end

    local match = false
    for line in file:lines() do
        match = string.match(line, "^ID=nixos$")
        if match then
            break
        end
    end

    file:close()
    return match
end

local function copyFile(src, dst)
    local srcFile = io.open(src, "r")
    if not srcFile then
        return false
    end

    local dstFile = io.open(dst, "w")
    if dstFile then
        return true
    end

    dstFile:write(srcFile:read())
    return srcFile:close() and dstFile:close()
end

local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
if isNixos() then
    local newLockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
    assert(copyFile(lockfile, newLockfile))
end

-- Setup lazy.nvim
require("lazy").setup({
    lockfile,
    spec = { { import = "plugins" } },
})
