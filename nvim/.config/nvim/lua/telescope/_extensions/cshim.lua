local exports = {}

local cshim = require("achmutov.cshim")

function exports.all(opts)
  opts = opts or {}

  local logs = cshim.log_list()
  local actions = require("telescope.actions")
  local conf = require("telescope.config").values

  require("telescope.pickers")
    .new(opts, {
      prompt_title = "Select log",
      initial_mode = "normal",
      finder = require("telescope.finders").new_table({
        results = vim.fn.reverse(logs),
        entry_maker = function(log)
          ---@cast log LogEntry
          return require("telescope.make_entry").set_default_entry_mt({
            value = log,
            display = log.name,
            ordinal = log.name,
            filename = log.path,
          })
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local log = require("telescope.actions.state").get_selected_entry().value
          actions.close(prompt_bufnr)
          cshim.open_path(log.path)
        end)
        return true
      end,
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

return require("telescope").register_extension({
  exports = exports,
})
