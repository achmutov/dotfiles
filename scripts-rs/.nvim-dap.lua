local dap = require("dap")

dap.configurations.rust = {
  {
    type = "codelldb",
    request = "launch",
    name = "temp",
    program = "./target/debug/tmux-bolt",
    args = {
      "@5",
    },
    cwd = "${workspaceFolder}",

    sourceLanguages = { "rust" },
  },
}
