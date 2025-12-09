local dap = require("dap")

dap.adapters["gdb-multiarch"] = {
    type = "executable",
    command = "gdb-multiarch",
    args = {
        "--quiet",
        "--interpreter=dap",
        "-ex",
        "target remote :3333",
        "-ex",
        "symbol-file build/zephyr/zephyr.elf",
    },
}

dap.configurations.c = {
    {
        type = "gdb-multiarch",
        name = "c-gdb",
        request = "launch",
        cwd = "${workspaceFolder}",
    },
}
