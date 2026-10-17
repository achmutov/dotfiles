local M = {}
local _enabled = false

local logger = require("achmutov.custom_info.logger")

M._timeout = 10000
M._index_ref = "info-full"
M._index_cmd = { "info-full" }
M._cmd_name = "CustomInfo"


local function init()
  local autogroup = vim.api.nvim_create_augroup("achmutov_custom_info", {})

  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = "info://*",
    nested = true,
    group = autogroup,
    callback = function(params)
      local ref = params.match:sub(#"info://" + 1)
      local log_opts = { schedule = true } ---@as InfoLogOpts

      local info_cmd
      if ref == M._index_ref then
        info_cmd = M._index_cmd
      else
        -- base
        info_cmd = { "info", "--file" }
        local file, node = ref:match("%(([^()]+)%)([^()]*)")
        if not file or not node then
          logger.error("couldn't parse ref: " .. ref, log_opts)
          return
        end

        -- optional node
        info_cmd = { "info", "--file", file }
        if #node ~= 0 then
          vim.list_extend(info_cmd, { "--node", node })
        end
      end

      local cmd_result = vim.system(info_cmd, { timeout = M._timeout, text = true }):wait()
      if cmd_result.code ~= 0 then
        logger.error("couldn't execute command", log_opts)
        return
      end

      local stdout = cmd_result.stdout
      vim.api.nvim_buf_set_lines(params.buf, 0, -1, false, vim.split(stdout or "", "\n"))
    end,
  })

  _enabled = true
end

local function open() end

function M.set_options()
  vim.bo.swapfile = false
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.bo.modified = false
  vim.bo.readonly = true
  vim.bo.modifiable = false
  vim.bo.filetype = "man"
end

--- @param pattern string
--- @return {name:string,filename:string,cmd:string}[]
function M.goto_tag(pattern, _, _)
  return {
    { name = "Info", filename = "info://" .. pattern, cmd = "1" },
  }
end

---@param params vim.api.keyset.create_user_command.command_args
function M.cmd(params)
  if not _enabled then
    init()
  end

  -- create ref
  local ref ---@type string?
  do
    local args = params.fargs

    -- usage
    if #args > 2 then
      logger.error(string.format("usage: %s [FILE] [NODE]", M._cmd_name))
      return
    end

    -- create ref
    if #args == 0 then
      ref = M._index_ref
    else -- 1 or 2
      local file = args[1]
      local node 
      ref = string.format("(%s)%s", args[1], args[2] or "")
    end
    logger.info("ref created " .. ref)
  end
  ---@cast ref -?

  local smods = params.smods

  -- goto ref
  do
    -- set the tagfunc
    local buf = vim.api.nvim_get_current_buf()
    local save_tfu = vim.bo[buf].tagfunc
    -- emmylua_ls for some reason breaks when they are connected, even if commented out
    vim.bo[buf].tagfunc = "v:lua.require" .. "'achmutov.custom_info'.goto_tag"

    -- follow tag
    local ok, ret = pcall(function()
      smods.silent = true
      smods.keepalt = true
      vim.cmd.tag({ ref, mods = smods })
    end)

    -- restore tagfunc
    if vim.api.nvim_buf_is_valid(buf) then
      vim.bo[buf].tagfunc = save_tfu
    end

    -- propagate error
    if not ok then
      logger.error(ret)
    end
  end

  -- set options in new buf
  M.set_options()
end

return M
