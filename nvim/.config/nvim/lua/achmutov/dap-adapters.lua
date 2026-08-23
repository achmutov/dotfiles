local dap = require("dap")

local M = {}

function M.setup()
  dap.adapters.python = {
    type = "executable",
    command = "debugpy-adapter",
  }

  local setup_lldb = function(conf, cb)
    local final_config = vim.deepcopy(conf)
    final_config.initCommands = final_config.initCommands or {}

    if conf.tty ~= nil then
      vim.list_extend(final_config.initCommands, {
        "settings set target.error-path " .. conf.tty,
        "settings set target.output-path " .. conf.tty,
        "settings set target.input-path " .. conf.tty,
      })
    end

    if conf.port ~= nil then
      local address = ""
      if conf.address ~= nil then
        address = conf.address .. ":"
      end
      vim.list_extend(final_config.initCommands, { "gdb-remote " .. address .. tostring(conf.port) })
    end

    cb(final_config)
  end

  dap.adapters.codelldb = {
    type = "executable",
    command = "codelldb",
    enrich_config = setup_lldb,
  }

  dap.adapters.lldb = {
    type = "executable",
    command = "lldb-dap",
    enrich_config = setup_lldb,
  }

  dap.adapters.gdb = function(cb, conf)
    local args = {
      "--quiet",
      "--interpreter=dap",
    }
    if conf.port ~= nil then
      local address = conf.address or ""
      vim.list_extend(args, {
        "-ex",
        "target remote " .. address .. ":" .. tostring(conf.port),
        "-ex",
        "symbol-file " .. conf.program,
      })
    end
    cb({
      type = "executable",
      command = "gdb",
      args = args,
    })
  end

  dap.adapters.cmake = {
    type = "pipe",
    pipe = "${pipe}",
    executable = {
      command = "sh",
      args = {
        "-c",
        "cmake --debugger --debugger-pipe=${pipe}",
      },
    },
  }
end

return M
