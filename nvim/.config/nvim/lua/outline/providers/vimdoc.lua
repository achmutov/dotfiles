local M = {
  name = "vimdoc",
}

-- Fix upstream classes: ------------------------------------------------------
-- * ProviderPosition is a table instead of a number
-- * parent is optional

---@class ProviderPosition
---@field character integer
---@field line integer

---@class ProviderSymbolRange
---@field start ProviderPosition
---@field end ProviderPosition

---@class ProviderSymbol
---@field name string
---@field kind integer
---@field detail? string
---@field range ProviderSymbolRange
---@field selectionRange ProviderSymbolRange
---@field parent? ProviderSymbol
---@field children ProviderSymbol[]

-------------------------------------------------------------------------------

---@class CustomProviderSymbol: ProviderSymbol
---@field _level integer
---@field children CustomProviderSymbol[]

---@alias VimdocTsKind "H1"|"H2"|"H3"|"H4"|"Tag"|"non-empty"

---@class VimdocInfo
---@field bufnr integer
---@field parser vim.treesitter.LanguageTree

---@param bufnr integer
---@param _ table?
---@return boolean, VimdocInfo?
function M.supports_buffer(bufnr, _)
  local ft = vim.bo[bufnr].filetype
  if ft ~= "help" then
    return false
  end

  local parser = vim.treesitter.get_parser(bufnr, "vimdoc")
  ---@cast parser -?

  return true, { bufnr = bufnr, parser = parser }
end

---@param info VimdocInfo
---@return ProviderSymbol[]
local function handle_vimdoc(info)
  local query = vim.treesitter.query.parse(
    "vimdoc",
    [[
        ([
            (h1 (heading) @H1 @non-empty)
            (h2 (heading) @H2 @non-empty)
            (h2 (heading) @H2 @non-empty)
            (h3 (heading) @H3 @non-empty)
            (column_heading (heading) @H4 @non-empty)
            (line (tag text: (word) @Tag @non-empty) . (tag text: (word) @Tag @non-empty)* .)
        ] (#not-lua-match? @non-empty "^%s*$"))
    ]]
  )

  ---@type table<string, integer>
  local str_to_kind = require("outline.symbols").str_to_kind

  local kind_by_ts_kind = {
    -- help_file = str_to_kind.Package,
    H1 = str_to_kind.Interface,
    H2 = str_to_kind.Interface,
    H3 = str_to_kind.Interface,
    H4 = str_to_kind.Interface,
    Tag = str_to_kind.Fragment,
  }

  local level_by_ts_kind = {
    -- root = 0,
    H1 = 1,
    H2 = 2,
    H3 = 3,
    Tag = 4,
    H4 = 5,
  }

  -- set `range.end` later
  ---@type CustomProviderSymbol
  local root = {
    name = "Root",
    parent = nil,
    kind = str_to_kind.Package,
    range = {
      start = { character = 0, line = 0 },
      ["end"] = { character = 0, line = 0 },
    },
    selectionRange = {
      start = { character = 0, line = 0 },
      ["end"] = { character = 0, line = 0 },
    },
    children = {},
    _level = 0,
  }

  local ts_tree = info.parser:parse()
  ---@cast ts_tree -?

  local current = root
  for id, node in query:iter_captures(ts_tree[1]:root(), info.bufnr) do
    repeat
      -- kind
      local ts_kind = query.captures[id]
      ---@cast ts_kind VimdocTsKind

      if ts_kind == "non-empty" then
        break
      end

      -- range
      local start_row, start_col, end_row, end_col = node:range()
      ---@type ProviderSymbolRange
      local range = {
        ["start"] = { line = start_row, character = start_col },
        ["end"] = { line = end_row, character = end_col },
      }

      -- name, should be one line
      local name = vim.api.nvim_buf_get_text(info.bufnr, start_row, start_col, end_row, end_col, {})[1]
      ---@cast name -?

      if
        ts_kind == "Tag"
        and current._level == level_by_ts_kind.Tag
        and range.start.line == current.range.start.line
      then
        current.name = current.name .. " " .. name
        break
      end

      -- level and parent
      local level = level_by_ts_kind[ts_kind]
      local parent = current
      while parent.parent and level <= parent._level do
        parent = parent.parent
      end

      -- add a child
      ---@type CustomProviderSymbol
      local new = {
        name = name,
        _level = level,
        kind = kind_by_ts_kind[ts_kind],
        range = range,
        selectionRange = range,
        children = {},
        parent = parent,
      }
      table.insert(parent.children, new)
      current = new
    until true
  end

  ---@param node CustomProviderSymbol
  ---@param _end integer
  local function traverse(node, _end)
    node.range["end"].line = _end

    -- change icon for non-leaf Tag
    if #node.children > 0 and node.kind == kind_by_ts_kind.Tag then
      node.kind = str_to_kind.Object
    end

    for i, child in ipairs(node.children) do
      local next_child = node.children[i + 1]
      if next_child ~= nil then
        traverse(child, next_child.range.start.line - 1)
      else
        traverse(child, _end)
      end
    end
  end
  traverse(root, vim.api.nvim_buf_line_count(info.bufnr))

  return root.children
end

---@param on_symbols fun(symbols?:ProviderSymbol[], opts?:table)
---@param opts table
---@param info VimdocInfo
function M.request_symbols(on_symbols, opts, info)
  on_symbols(handle_vimdoc(info), opts)
end

return M
