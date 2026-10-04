local T = {
  none = "__none",
  auto = "__auto",
  lsp = vim.F.if_nil,
}

local mason2lsp = {
  -- github
  ["clangd"] = T.auto,
  ["codelldb"] = T.none,
  ["shellcheck"] = T.none,
}
-- ["lua-language-server"] = "lua_ls",
-- ["pyright"] = SAME,
-- ["typescript-language-server"] = "ts_ls",

local system_lsp = {
  "bashls", -- needs shellcheck, shfmt
  "cssls",
  "docker_language_server",
  "emmylua_ls",
  "gh_actions_ls",
  "gopls",
  "just",
  "neocmake",
  "oxfmt",
  "oxlint",
  "ruff",
  "rust_analyzer",
  "stylua",
  "tailwindcss",
  "taplo",
  "ts_query_ls",
  "tsc",
  "ty",
  "typos_lsp",
  "zls",

  -- TODO: better installation
  -- Mason pulls these from unmaintained hrsh7th/vscode-langservers-extracted
  -- There's T1ckbase/vscode-langservers-extracted, but it isn't used by many
  "cssls",
  "eslint",
  "html",
  "jsonls",
}

local mason = vim.tbl_keys(mason2lsp)
local mason_lsp = vim
  .iter(pairs(mason2lsp))
  :map(function(mason_name, lsp_name)
    if lsp_name == T.auto then
      return mason_name
    elseif lsp_name == T.none then
      return nil
    else
      return lsp_name
    end
  end)
  :totable()

return {
  mason = mason,
  lsp = vim.list_extend(mason_lsp, system_lsp),
}
