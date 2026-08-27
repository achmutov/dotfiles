local T = {
  none = "__none",
  auto = "__auto",
  lsp = vim.F.if_nil,
}

local mason2lsp = {
  -- npm
  ["bash-language-server"] = T.lsp("bashls"), -- needs shellcheck, shfmt
  ["css-lsp"] = T.lsp("cssls"),
  ["docker-compose-language-service"] = T.lsp("docker_compose_language_service"),
  ["eslint-lsp"] = T.lsp("eslint"),
  ["gh-actions-language-server"] = T.lsp("gh_actions_ls"),
  ["html-lsp"] = "html",
  ["json-lsp"] = T.lsp("jsonls"),
  ["tailwindcss-language-server"] = T.lsp("tailwindcss"),
  ["vue-language-server"] = T.lsp("vue_ls"),
  ["yaml-language-server"] = T.lsp("yamlls"),

  -- github
  ["clangd"] = T.auto,
  ["codelldb"] = T.none,
  ["shellcheck"] = T.none,
}
-- ["lua-language-server"] = "lua_ls",
-- ["pyright"] = SAME,
-- ["typescript-language-server"] = "ts_ls",

local system_lsp = {
  "docker_language_server",
  "emmylua_ls",
  "gopls",
  "just",
  "neocmake",
  "oxfmt",
  "oxlint",
  "ruff",
  "rust_analyzer",
  "stylua",
  "taplo",
  "tsc",
  "ty",
  "typos_lsp",
  "zls",
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
