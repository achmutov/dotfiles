local dap = require("dap")

dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch the module",

        -- Module
        module = "kenning",
        pythonPath = vim.fn.getcwd() .. "/.venv/bin/python",

        -- Pass CLI arguments
        args = {
            -- luacheck: push ignore
            "optimize test --json-cfg scripts/jsonconfigs/mobilenetv2-tensorflow-tvm-avx-int8.json --measurements output.json",
            -- luacheck: pop
        },
    },
}
