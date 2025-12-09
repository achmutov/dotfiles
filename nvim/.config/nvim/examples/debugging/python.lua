local dap = require("dap")

dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch the module",

        -- Enable terminal
        console = "integratedTerminal",

        -- Module
        module = "modulename",

        -- Pass CLI arguments
        args = { "arg1", "arg2" },
    },
}
