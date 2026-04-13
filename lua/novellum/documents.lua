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

local function run_stitch(root, args, callback, opts)
  require("novellum.cli").run_plain(root, "stitch", args, function(err, result)
    if err ~= nil then
      require("novellum.notify").error(err)
      if callback then
        callback(false, result)
      end
      return
    end
    if not (opts and opts.quiet_success) then
      notify_result("Stitch complete.", result)
    end
    if callback then
      callback(true, result)
    end
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

local function current_note_id(root, notes)
  local current_path = vim.api.nvim_buf_get_name(0)
  if current_path == "" then
    return nil
  end

  current_path = vim.fs.normalize(current_path)
  for _, note in ipairs(notes) do
    local note_path = vim.fs.normalize(root .. "/" .. note.path)
    if note_path == current_path then
      return note.id
    end
  end

  return nil
end

function M.stitch(root, args)
  if args ~= nil and #args > 0 then
    require("novellum.build").set_session({
      root = root,
      stitch_args = vim.deepcopy(args),
      compile_target = "stitched",
    })
    run_stitch(root, args)
    return
  end

  prompt_stitch_mode(function(mode)
    if mode == "all" then
      with_stitch_metadata(function(title, output)
        local stitch_args = append_common_stitch_options({ "--all" }, title, output)
        require("novellum.build").set_session({
          root = root,
          stitch_args = vim.deepcopy(stitch_args),
          compile_target = "stitched",
        })
        run_stitch(root, stitch_args)
      end)
      return
    end

    if mode == "category" then
      prompt_category(function(category)
        with_stitch_metadata(function(title, output)
          local stitch_args = append_common_stitch_options({ category.flag }, title, output)
          require("novellum.build").set_session({
            root = root,
            stitch_args = vim.deepcopy(stitch_args),
            compile_target = "stitched",
          })
          run_stitch(root, stitch_args)
        end)
      end)
      return
    end

    require("novellum.notify").info("Use <C-b> to mark notes and <M-CR> to stitch marked notes in mini.pick.")
    local notes, err = require("novellum.cache").get_notes(root)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end
    local active_note_id = current_note_id(root, notes)

    require("novellum.picker").pick_notes(root, notes, {
      name = "Novellum Stitch",
      pre_mark_ids = active_note_id ~= nil and { active_note_id } or {},
      initial_current_id = active_note_id,
      on_choice = function(note)
        with_stitch_metadata(function(title, output)
          local stitch_args = append_common_stitch_options({ note.id }, title, output)
          require("novellum.build").set_session({
            root = root,
            stitch_args = vim.deepcopy(stitch_args),
            compile_target = "stitched",
          })
          run_stitch(root, stitch_args)
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
          stitch_args = append_common_stitch_options(stitch_args, title, output)
          require("novellum.build").set_session({
            root = root,
            stitch_args = vim.deepcopy(stitch_args),
            compile_target = "stitched",
          })
          run_stitch(root, stitch_args)
        end)
      end,
    })
  end)
end

function M.compile(root, target, callback, opts)
  local compile_target = target ~= "" and target or "stitched"
  require("novellum.cli").run_plain(root, "compile", { compile_target }, function(err, result)
    if err ~= nil then
      require("novellum.notify").error(("Compile failed for %s."):format(compile_target))
      if require("novellum.config").get().documents.quickfix_on_compile_error then
        populate_quickfix("Novellum Compile", (result.stdout or "") .. "\n" .. (result.stderr or ""))
      end
      if callback then
        callback(false, result)
      end
      return
    end
    if not (opts and opts.quiet_success) then
      require("novellum.notify").info(("Compiled %s."):format(compile_target))
    end
    if callback then
      callback(true, result)
    end
  end)
end

function M.run_session(session, callback, opts)
  run_stitch(session.root, session.stitch_args, function(ok)
    if not ok then
      if callback then
        callback(false)
      end
      return
    end

    M.compile(session.root, session.compile_target or "stitched", function(compiled)
      if callback then
        callback(compiled)
      end
    end, opts)
  end, opts)
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
