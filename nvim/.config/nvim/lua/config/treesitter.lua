---@diagnostic disable: missing-fields

---@diagnostic disable-next-line: unused-local
local function big_file(_lang, buf)
    local max_filesize = 100 * 1024 -- 100 KB

    ---@diagnostic disable-next-line: undefined-field
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > max_filesize then
        return true
    end
end

require("nvim-treesitter.configs").setup({
    ensure_installed = {
        "c",
        "cpp",
        "python",
        "rust",
        "lua",
        "latex",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,

        -- Disable for big files
        disable = big_file,

        additional_vim_regex_highlighting = false,
    },
})
