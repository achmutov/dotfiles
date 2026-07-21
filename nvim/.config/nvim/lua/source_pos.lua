-- inspired by https://github.com/lewis6991/fileline.nvim
local function focus()
  local input_name = vim.api.nvim_buf_get_name(0)

  -- validate
  if input_name == "" then
    vim.notify("source_pos: empty file", vim.log.levels.WARN)
    return
  end
  if input_name:match("^([^:]+)$") then
    vim.notify("source_pos: no pos suffix found: " .. input_name)
    return
  end

  -- parse
  ---@type string?, number?, number?
  local file_name, line, col
  repeat
    local line_str, col_str

    file_name, line_str, col_str = input_name:match("^([^:]+):(%d+):(%d+)$")
    if file_name ~= nil then
      line = tonumber(line_str)
      col = tonumber(col_str)
      vim.notify("source_pos: found line and col: " .. line_str .. ":" .. col_str, vim.log.levels.INFO)
      break
    end

    file_name, line_str = input_name:match("^([^:]+):(%d+)$")
    if file_name ~= nil then
      line = tonumber(line_str)
      vim.notify("source_pos: found line: " .. line_str, vim.log.levels.INFO)
      break
    end

    vim.notify("source_pos: couldn't parse position: " .. input_name, vim.log.levels.INFO)
    return
  until false

  ---@cast file_name string
  ---@cast line -?

  -- check if file was created
  if vim.fn.filereadable(file_name) == 0 then
    return
  end

  -- reopen
  do
    local old_bufnr = vim.api.nvim_get_current_buf()
    vim.cmd.edit({ vim.fn.fnameescape(file_name), mods = { keepalt = true } })
    vim.schedule(function()
      vim.api.nvim_buf_delete(old_bufnr, {})
    end)
  end

  -- navigate
  line = math.min(line, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { line, col and col - 1 or 0 })
  vim.cmd.normal({ "zz", bang = true })
end

return { focus = focus }
