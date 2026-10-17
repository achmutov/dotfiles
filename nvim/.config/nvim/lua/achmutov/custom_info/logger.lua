local M = {}

---@class InfoLogOpts
---@field schedule boolean

---@param msg string
---@param level vim.log.levels
---@param opts? InfoLogOpts
function M.log(msg, level, opts)
  if opts and opts.schedule then
    vim.schedule(function()
      vim.notify("gnu info: " .. msg, level)
    end)
  else
    vim.notify("gnu info: " .. msg, level)
  end
end

---@param msg string
---@param opts? InfoLogOpts
function M.info(msg, opts)
  M.log(msg, vim.log.levels.INFO, opts)
end

---@param msg string
---@param opts? InfoLogOpts
function M.error(msg, opts)
  M.log(msg, vim.log.levels.ERROR, opts)
end

return M
