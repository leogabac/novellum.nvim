local M = {}

local function command_prefix()
  local configured = require("novellum.config").get().command
  if type(configured) == "string" then
    return { configured }
  end
  return vim.deepcopy(configured)
end

local function build_command(root, subcommand, args, json)
  local argv = command_prefix()
  if json then
    table.insert(argv, "--json")
  end

  table.insert(argv, subcommand)
  vim.list_extend(argv, args or {})
  table.insert(argv, "--cwd")
  table.insert(argv, root)

  return argv
end

local function normalize_error(result, parsed)
  if parsed and parsed.error and parsed.error.message then
    return parsed.error.message
  end
  if result.stderr and result.stderr ~= "" then
    return vim.trim(result.stderr)
  end
  return ("Command failed with exit code %s"):format(result.code)
end

function M.run_json(root, subcommand, args, callback)
  local argv = build_command(root, subcommand, args, true)
  vim.system(argv, { text = true, cwd = root }, function(result)
    vim.schedule(function()
      local ok, parsed = pcall(vim.json.decode, result.stdout or "")
      if result.code ~= 0 then
        callback(normalize_error(result, ok and parsed or nil), nil, result)
        return
      end
      if not ok then
        callback("Failed to decode novellum JSON output.", nil, result)
        return
      end
      callback(nil, parsed, result)
    end)
  end)
end

function M.run_plain(root, subcommand, args, callback)
  local argv = build_command(root, subcommand, args, false)
  vim.system(argv, { text = true, cwd = root }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(normalize_error(result, nil), result)
        return
      end
      callback(nil, result)
    end)
  end)
end

function M.run_json_sync(root, subcommand, args, timeout_ms)
  local argv = build_command(root, subcommand, args, true)
  local completed = vim.system(argv, { text = true, cwd = root }):wait(timeout_ms or 5000)
  if completed.code ~= 0 then
    local ok, parsed = pcall(vim.json.decode, completed.stdout or "")
    return nil, normalize_error(completed, ok and parsed or nil), completed
  end

  local ok, parsed = pcall(vim.json.decode, completed.stdout or "")
  if not ok then
    return nil, "Failed to decode novellum JSON output.", completed
  end
  return parsed, nil, completed
end

return M
