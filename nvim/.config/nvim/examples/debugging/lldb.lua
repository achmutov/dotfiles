local dap = require("dap")

dap.configurations.c = {
    {
        type = "lldb",
        request = "launch",
        name = "Launch the file",
        program = "path/to/file",
        args = { "arg1", "arg2", "<", "path/to/stdin/file" },
    },
}
