-- inspired by https://github.com/nvim-telescope/telescope-dap.nvim

-- TODO: multithreading

local dap = require("dap")

local exports = {}

function exports.breakpoints(opts)
  opts = opts or {}
  opts.prompt_title = "Dap Breakpoints"
  dap.list_breakpoints(false)
  require("telescope.builtin").quickfix(opts)
end

function exports.frames(opts)
  opts = opts or {}

  local session = dap.session()
  if not session then
    vim.notify("No active session", vim.log.levels.INFO)
    return
  end

  local stopped_thread_id = session.stopped_thread_id
  if not stopped_thread_id then
    vim.notify("Thread is not stopped", vim.log.levels.INFO)
    return
  end

  local thread_frames = assert(session.threads[stopped_thread_id].frames, "expected frames")
  local current_frame_index = vim.iter(thread_frames):enumerate():find(function(_, v)
    return v == session.current_frame
  end)

  local displayer = require("telescope.pickers.entry_display").create({
    separator = " ",
    items = {
      { width = 0.5 },
      { remaining = true },
    },
  })

  local actions = require("telescope.actions")
  local conf = require("telescope.config").values
  require("telescope.pickers")
    .new(opts, {
      prompt_title = "Jump to frame",
      initial_mode = "normal",
      default_selection_index = current_frame_index,
      finder = require("telescope.finders").new_table({
        results = thread_frames,
        entry_maker = function(frame)
          local make_display = function(display_frame)
            local display_filename, path_style = require("telescope.utils").transform_path(opts, display_frame.filename)
            local display_position = string.format("%s:%d:%d", display_filename, display_frame.lnum, display_frame.col)

            local display_name = vim.trim(display_frame.text)
            local display_name_style
            local hint = frame.source and frame.source.presentationHint or nil
            if hint == "subtle" or hint == "deemphasize" or not frame.source then
              display_name_style = "NvimDapHiddenFrame"
            end

            return displayer({
              { display_position, path_style },
              { display_name, display_name_style },
            })
          end
          return {
            value = frame,
            display = make_display,
            ordinal = frame.name,
            text = frame.name,
            filename = frame.source and frame.source.path or "",
            lnum = frame.line or 1,
            col = frame.column or 0,
          }
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local frame = require("telescope.actions.state").get_selected_entry().value
          actions.close(prompt_bufnr)
          session:_frame_set(frame)
        end)
        return true
      end,
      previewer = conf.qflist_previewer(opts),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

return require("telescope").register_extension({
  setup = function()
    vim.api.nvim_set_hl(0, "NvimDapHiddenFrame", { default = true, link = "Comment" })
  end,
  exports = exports,
})
