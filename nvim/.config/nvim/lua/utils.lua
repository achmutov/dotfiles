local M = {}

---@param val integer
function M.toggleScrolloff(val)
    return function()
        local inf = 9999
        if vim.o.so == inf then
            vim.o.so = val
        else
            vim.o.so = inf
        end
    end
end

function M.toggleTrailingBackslash()
    require("math")

    -- Get lines under selection
    local _, l1, _, _ = unpack(vim.fn.getpos("."))
    local _, l2, _, _ = unpack(vim.fn.getpos("v"))
    local start_line = math.min(l1, l2)
    local end_line = math.max(l1, l2)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line - 1, false)

    -- ??? treats tabs as spaces, debatable but fancy looking
    local function get_len(v)
        return string.len(string.gsub(v, "\t", string.rep(" ", tonumber(vim.bo.tabstop) or 4)))
    end

    local has_backslash = false
    local longest = 0
    for i, line in ipairs(lines) do
        -- trim trailing ws
        line = string.gsub(line, " *$", "")

        -- measure longest line
        longest = math.max(longest, get_len(line))

        -- check trailing bachslash
        has_backslash = has_backslash or string.find(line, "\\$") ~= nil
        lines[i] = line
    end

    for i, line in ipairs(lines) do
        if has_backslash then
            -- Remove all trailing backslashes
            line = string.gsub(line, " *\\$", "")
        else
            -- Insert wrapped trailing backslashes
            local rep = longest - get_len(line)
            line = line .. string.rep(" ", rep) .. " \\"
        end

        lines[i] = line
    end

    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line - 1, false, lines)
end

function M.removeTrailingWhitespace()
    local start_line, end_line
    if vim.api.nvim_get_mode().mode == "n" then
        start_line = 0
        end_line = -1
    else
        local _, l1, _, _ = unpack(vim.fn.getpos("."))
        local _, l2, _, _ = unpack(vim.fn.getpos("v"))
        start_line = math.min(l1, l2)
        end_line = math.max(l1, l2)
    end

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
    for i, line in ipairs(lines) do
        lines[i] = string.gsub(line, " *$", "")
    end
    vim.api.nvim_buf_set_lines(0, start_line, end_line, false, lines)
end

--- https://github.com/nvim-treesitter/nvim-treesitter/issues/1167#issuecomment-920824125
---@param fallback function
function M.jsdoc_indent(fallback)
    local line = vim.fn.getline(vim.v.lnum)
    local prev_line = vim.fn.getline(vim.v.lnum - 1)
    if line:match("^%s*[%*/]%s*") then
        if prev_line:match("^%s*%*%s*") then
            return vim.fn.indent(vim.v.lnum - 1)
        end
        if prev_line:match("^%s*/%*%*%s*$") then
            return vim.fn.indent(vim.v.lnum - 1) + 1
        end
    end

    return fallback()
end

function M.XGetJavascriptIndent()
    return M.jsdoc_indent(vim.fn.GetJavascriptIndent)
end

function M.XGetTypescriptIndent()
    return M.jsdoc_indent(vim.fn.GetTypescriptIndent)
end

return M
