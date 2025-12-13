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

vim.keymap.set("v", ">", ">gv", { noremap = true })
vim.keymap.set("v", "<", "<gv", { noremap = true })

vim.keymap.set("v", "<leader>\\", function()
    require("math")

    -- Get entire lines under selection
    local _, l1, _, _ = unpack(vim.fn.getpos("."))
    local _, l2, _, _ = unpack(vim.fn.getpos("v"))
    local start_line = math.min(l1, l2)
    local end_line = math.max(l1, l2)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line - 1, false)

    -- ??? treats tabs as spaces, debatable but fancy looking
    local function get_len(v)
        return string.len(string.gsub(v, "\t", string.rep(" ", tonumber(vim.opt_local) or 4)))
    end

    -- First pass
    local temp_lines = {}
    local has_backslash = false
    local longest = 0

    for _, v in ipairs(lines) do
        -- trim trailing ws
        v = string.gsub(v, " *$", "")

        -- measure longest line
        longest = math.max(longest, get_len(v))

        -- check trailing bachslash
        has_backslash = has_backslash or string.find(v, "\\$") ~= nil

        table.insert(temp_lines, v)
    end

    -- Second pass
    local new_lines = {}
    for _, v in ipairs(temp_lines) do
        if has_backslash then
            -- Remove all trailing backslashes
            v = string.gsub(v, " *\\$", "")
        else
            -- Insert wrapped trailing backslashes
            local rep = longest - get_len(v)
            v = v .. string.rep(" ", rep) .. " \\"
        end

        table.insert(new_lines, v)
    end

    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line - 1, false, new_lines)
end)
