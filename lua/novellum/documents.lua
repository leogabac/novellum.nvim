local M = {}

local stitch_categories = {
  { label = "concept", flag = "--concepts" },
  { label = "proof", flag = "--proofs" },
  { label = "paper", flag = "--papers" },
  { label = "experiment", flag = "--experiments" },
  { label = "question", flag = "--questions" },
  { label = "log", flag = "--logs" },
  { label = "ref", flag = "--refs" },
}

local function populate_quickfix(title, content)
  local lines = vim.split(content or "", "\n", { trimempty = true })
  if #lines == 0 then
    return
  end

  local items = vim.tbl_map(function(line)
    return { text = line }
  end, lines)

  vim.fn.setqflist({}, " ", {
    title = title,
    items = items,
  })
  vim.cmd.copen()
end

local function notify_result(prefix, result)
  local message = vim.trim(result.stdout or "")
  if message == "" then
    message = prefix
  end
  require("novellum.notify").info(message)
end

local function open_terminal_split(title)
  local previous = vim.api.nvim_get_current_win()
  vim.cmd("botright 12split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_height(win, 12)
  vim.bo[buf].buflisted = false
  vim.api.nvim_buf_set_name(buf, title)
  return previous, win, buf
end

local function run_stitch(root, args)
  require("novellum.cli").run_plain(root, "stitch", args, function(err, result)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end
    notify_result("Stitch complete.", result)
  end)
end

local function prompt_title(callback)
  vim.ui.input({ prompt = "Stitch title: ", default = "Novellum Stitch" }, function(input)
    if input == nil or input == "" then
      callback("Novellum Stitch")
      return
    end
    callback(input)
  end)
end

local function prompt_output(callback)
  vim.ui.input({ prompt = "Output path (optional): " }, function(input)
    if input == nil then
      return
    end
    callback(vim.trim(input))
  end)
end

local function with_stitch_metadata(callback)
  prompt_title(function(title)
    prompt_output(function(output)
      callback(title, output)
    end)
  end)
end

local function append_common_stitch_options(args, title, output)
  table.insert(args, "--title")
  table.insert(args, title)
  if output ~= nil and output ~= "" then
    table.insert(args, "--output")
    table.insert(args, output)
  end
  return args
end

local function prompt_category(callback)
  vim.ui.select(stitch_categories, {
    prompt = "Stitch category",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item == nil then
      return
    end
    callback(item)
  end)
end

local function prompt_stitch_mode(callback)
  vim.ui.select({
    { mode = "selected", label = "Selected notes" },
    { mode = "all", label = "All notes" },
    { mode = "category", label = "By category" },
  }, {
    prompt = "Stitch mode",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item == nil then
      return
    end
    callback(item.mode)
  end)
end

function M.stitch(root, args)
  if args ~= nil and #args > 0 then
    run_stitch(root, args)
    return
  end

  prompt_stitch_mode(function(mode)
    if mode == "all" then
      with_stitch_metadata(function(title, output)
        run_stitch(root, append_common_stitch_options({ "--all" }, title, output))
      end)
      return
    end

    if mode == "category" then
      prompt_category(function(category)
        with_stitch_metadata(function(title, output)
          run_stitch(root, append_common_stitch_options({ category.flag }, title, output))
        end)
      end)
      return
    end

    require("novellum.notify").info("Use <C-x> to mark notes and <M-CR> to stitch marked notes in mini.pick.")
    local notes, err = require("novellum.cache").get_notes(root)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end

    require("novellum.picker").pick_notes(root, notes, {
      name = "Novellum Stitch",
      on_choice = function(note)
        with_stitch_metadata(function(title, output)
          run_stitch(root, append_common_stitch_options({ note.id }, title, output))
        end)
      end,
      on_choice_marked = function(selected)
        if #selected == 0 then
          return
        end
        with_stitch_metadata(function(title, output)
          local stitch_args = vim.tbl_map(function(note)
            return note.id
          end, selected)
          run_stitch(root, append_common_stitch_options(stitch_args, title, output))
        end)
      end,
    })
  end)
end

function M.compile(root, target)
  local compile_target = target ~= "" and target or "stitched"
  local argv = require("novellum.cli").argv(root, "compile", { compile_target }, false)
  local previous_win, _, terminal_buf = open_terminal_split(("novellum compile %s"):format(compile_target))

  vim.fn.termopen(argv, {
    cwd = root,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          require("novellum.notify").info(("Compiled %s."):format(compile_target))
        else
          require("novellum.notify").error(("Compile failed for %s."):format(compile_target))
          if require("novellum.config").get().documents.quickfix_on_compile_error then
            populate_quickfix(
              "Novellum Compile",
              table.concat(vim.api.nvim_buf_get_lines(terminal_buf, 0, -1, false), "\n")
            )
          end
        end
        if vim.api.nvim_win_is_valid(previous_win) then
          vim.api.nvim_set_current_win(previous_win)
        end
      end)
    end,
  })
  vim.cmd("startinsert")
end

function M.open_pdf(root, target)
  local open_target = target ~= "" and target or "stitched"
  require("novellum.cli").run_plain(root, "open", { open_target }, function(err, result)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end
    notify_result(("Opened %s."):format(open_target), result)
  end)
end

return M
