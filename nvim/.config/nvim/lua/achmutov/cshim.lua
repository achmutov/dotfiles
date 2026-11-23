local M = {}

function M.log_path()
  return (vim.env.XDG_STATE_HOME or vim.env.HOME .. ".local/state") .. "/cshim"
end

---@class LogEntry
---@field name string
---@field path string
---@field type string

function M.log_list()
  ---@type LogEntry[]
  local output = {}
  local log_path = M.log_path()
  for filename, filetype in vim.fs.dir(log_path) do
    if filetype == "file" and filename:match("%.log$") then
      local log_type = filename:sub(25)
      log_type = log_type:sub(1, -5)

      output[#output + 1] = {
        name = filename,
        path = log_path .. "/" .. filename,
        type = log_type,
      }
    end
  end
  return output
end

---@param log_type string?
function M.log_last(log_type)
  local logs = M.log_list()
  for i = #logs, 1, -1 do
    local log = logs[i]
    if log_type == nil or log_type == log.type then
      return log
    end
  end
end

function M.open_last(log_type)
  local log = M.log_last(log_type)
  if log ~= nil then
    M.open_path(log.path)
  else
    if log_type == nil then
      vim.notify("cshim: no log found")
    else
      vim.notify(string.format("cshim: no log found of type '%s'", log_type))
    end
  end
end

---@param path string
function M.open_path(path)
  vim.cmd.cfile(path)
  vim.cmd.copen()
end

return M
