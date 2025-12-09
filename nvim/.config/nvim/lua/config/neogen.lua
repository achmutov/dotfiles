require("neogen").setup({
    enabled = true,
    languages = {
        python = {
            template = {
                -- annotation_convention = "numpydoc"
                annotation_convention = "google_docstrings",
            },
        },
    },
})

vim.keymap.set("n", "<leader>ng", vim.cmd.Neogen)
