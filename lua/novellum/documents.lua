local M = {}

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

function M.stitch(root, args)
  if args ~= nil and #args > 0 then
    run_stitch(root, args)
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
      prompt_title(function(title)
        run_stitch(root, { note.id, "--title", title })
      end)
    end,
    on_choice_marked = function(selected)
      if #selected == 0 then
        return
      end
      prompt_title(function(title)
        local stitch_args = vim.tbl_map(function(note)
          return note.id
        end, selected)
        table.insert(stitch_args, "--title")
        table.insert(stitch_args, title)
        run_stitch(root, stitch_args)
      end)
    end,
  })
end

function M.compile(root, target)
  local compile_target = target ~= "" and target or "workspace"
  require("novellum.cli").run_plain(root, "compile", { compile_target }, function(err, result)
    if err ~= nil then
      if require("novellum.config").get().documents.quickfix_on_compile_error then
        populate_quickfix("Novellum Compile", (result.stdout or "") .. "\n" .. (result.stderr or ""))
      end
      require("novellum.notify").error(err)
      return
    end
    notify_result(("Compiled %s."):format(compile_target), result)
  end)
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
