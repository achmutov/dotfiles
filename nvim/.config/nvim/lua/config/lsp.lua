local inlayHints = {
    includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all'
    includeInlayParameterNameHintsWhenArgumentMatchesName = true,
    includeInlayFunctionParameterTypeHints = true,
    includeInlayVariableTypeHints = true,
    includeInlayVariableTypeHintsWhenTypeMatchesName = true,
    includeInlayPropertyDeclarationTypeHints = true,
    includeInlayFunctionLikeReturnTypeHints = true,
    includeInlayEnumMemberValueHints = true,
}
vim.lsp.config("ts_ls", {
    init_options = {
        plugins = {
            {
                name = "@vue/typescript-plugin",
                location = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server"),
                languages = { "vue" },
            },
        },
    },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
    settings = {
        typescript = { inlayHints = inlayHints },
        javascript = { inlayHints = inlayHints },
    },
})
vim.lsp.config("gh_actions_ls", {
    filetypes = { "yaml.github" },
    root_markers = { ".github" },
    single_file_support = true,
    capabilities = {
        workspace = {
            didChangeWorkspaceFolders = { dynamicRegistration = true },
        },
    },
})
vim.lsp.config("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            check = { command = "clippy" },
        },
    },
})
