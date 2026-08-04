local T = {
  none = "__none",
  auto = "__auto",
  lsp = vim.F.if_nil,
}

local mason2lsp = {
  -- npm
  ["bash-language-server"] = T.lsp("bashls"),
  ["css-lsp"] = T.lsp("cssls"),
  ["docker-compose-language-service"] = T.lsp("docker_compose_language_service"),
  ["docker-language-server"] = T.lsp("docker_language_server"),
  ["eslint-lsp"] = T.lsp("eslint"),
  ["gh-actions-language-server"] = T.lsp("gh_actions_ls"),
  ["json-lsp"] = T.lsp("jsonls"),
  ["oxfmt"] = T.auto,
  ["oxlint"] = T.auto,
  ["tailwindcss-language-server"] = T.lsp("tailwindcss"),
  ["tsgo"] = T.auto,
  ["vue-language-server"] = T.lsp("vue_ls"),
  ["yaml-language-server"] = T.lsp("yamlls"),

  -- github
  ["clangd"] = T.auto,
  ["codelldb"] = T.none,
  ["shellcheck"] = T.none,
  ["shfmt"] = T.none,
}
-- ["lua-language-server"] = "lua_ls",
-- ["pyright"] = SAME,
-- ["typescript-language-server"] = "ts_ls",

local system_lsp = {
  "emmylua_ls",
  "gopls",
  "just",
  "neocmake",
  "ruff",
  "rust_analyzer",
  "stylua",
  "taplo",
  "ty",
  "typos_lsp",
  "zls",
}

local treesitter = {
  "asm",
  "bash",
  "c",
  "c_sharp",
  "cmake",
  "cpp",
  "css",
  "devicetree",
  "diff",
  "git_commit",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "html",
  "java",
  "javascript",
  "jsdoc",
  "json",
  "just",
  "kconfig",
  "kotlin",
  "latex",
  "lua",
  "make",
  "markdown",
  "nasm",
  "nginx",
  "python",
  "r",
  "requirements",
  "robot",
  "ron",
  "rst",
  "rust",
  "scss",
  "ssh_config",
  "svelte",
  "tmux",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vue",
  "xml",
  "yaml",
  "zig",
  "zsh",
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
  treesitter = treesitter,
}
