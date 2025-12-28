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

return {
    init_options = {
        plugins = {
            {
                name = "@vue/typescript-plugin",
                location = vim.fn.stdpath("data")
                    .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
                languages = { "vue" },
            },
        },
    },
    filetypes = {
        -- lspconfig
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        -- lspconfig
        "vue",
    },
    settings = {
        typescript = { inlayHints = inlayHints },
        javascript = { inlayHints = inlayHints },
    },
}
