local neogit = require("neogit")
neogit.setup({
    disable_hint = true,
    disable_context_highlighting = true,
    graph_style = "unicode",
    highlight = {
        bg1 = "",
    },
    integrations = {
        telescope = true,
        diffview = true,
    },
})

vim.keymap.set("n", "<leader>gs", function()
    neogit.open({ kind = "replace" })
end)

local diffview = require("diffview")

vim.keymap.set("n", "<leader>gv", diffview.open)
vim.keymap.set("n", "<leader>gc", diffview.close)
