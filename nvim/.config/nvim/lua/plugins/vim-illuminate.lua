return {
    "RRethy/vim-illuminate",
    config = function()
        vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#ffffff", fg = "#000000" })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = "#83a598", fg = "#ffffff" })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "#fb4934", fg = "#ffffff" })

        local illuminate = require("illuminate")
        local engine = require("illuminate.engine")
        illuminate.configure({ delay = 0 })
        illuminate.pause()

        vim.keymap.set({ "n", "i" }, "<C-l>", function()
            illuminate.unfreeze_buf()
            illuminate.pause()
            vim.cmd("noh")
        end)

        vim.keymap.set("n", "<leader>o", function()
            if illuminate.is_paused() then
                illuminate.resume()
            else
                illuminate.toggle_freeze_buf()
                engine.refresh_references()
            end
        end)
    end,
}
