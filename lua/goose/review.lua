local Path = require('plenary.path')
local M = {}

-- Git helpers
local git = {
  is_project = function()
    -- Cache result
    if M.__is_git_project ~= nil then
      return M.__is_git_project
    end
    local git_dir = Path:new(vim.fn.getcwd()):joinpath('.git')
    M.__is_git_project = git_dir:exists() and git_dir:is_dir()
    return M.__is_git_project
  end,

  list_changed_files = function()
    local handle = io.popen('git ls-files -m -o --exclude-standard')
    local result = handle:read('*a')
    handle:close()
    return result
  end,

  is_tracked = function(file_path)
    return os.execute('git ls-files --error-unmatch "' .. file_path .. '" > /dev/null 2>&1') == 0
  end,

  get_head_content = function(file_path, output_path)
    return os.execute('git show HEAD:"' .. file_path .. '" > ' .. output_path .. ' 2>/dev/null') == 0
  end
}

-- Decorator for git project checks
local function require_git_project(fn, silent)
  return function(...)
    if not git.is_project() then
      if not silent then
        vim.notify("Error: Not in a git project.")
      end
      return
    end
    return fn(...)
  end
end

-- File helpers
local function get_snapshot_dir()
  local cwd = vim.fn.getcwd()
  local cwd_hash = vim.fn.sha256(cwd)
  return Path:new(vim.fn.stdpath('data')):joinpath('goose', 'snapshot', cwd_hash)
end

local function show_diff(file_path, snapshot_path)
  local file_path_str = tostring(file_path)
  local snapshot_path_str = snapshot_path and tostring(snapshot_path) or nil

  if snapshot_path_str then
    -- Compare with snapshot file
    vim.cmd('edit ' .. snapshot_path_str)
    vim.cmd('setlocal readonly buftype=nofile nomodifiable')
    vim.cmd('diffthis')
    local temp_buf = vim.api.nvim_get_current_buf()
    local temp_win = vim.api.nvim_get_current_win()

    vim.cmd('vsplit ' .. file_path_str)
    vim.cmd('diffthis')

    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(temp_win),
      callback = function()
        if vim.api.nvim_buf_is_valid(temp_buf) then
          vim.api.nvim_buf_delete(temp_buf, { force = true })
        end
      end,
      once = true
    })
  else
    -- If file is tracked by git, compare with HEAD, otherwise just open it
    local temp_file = Path:new(vim.fn.tempname())
    if git.get_head_content(file_path_str, tostring(temp_file)) then
      vim.cmd('edit ' .. file_path_str)
      local file_type = vim.bo.filetype
      vim.cmd('leftabove vsplit ' .. tostring(temp_file))
      vim.cmd('setlocal readonly buftype=nofile nomodifiable filetype=' .. file_type)

      local temp_buf = vim.api.nvim_get_current_buf()
      local temp_win = vim.api.nvim_get_current_win()
      vim.cmd('diffthis')
      vim.cmd('wincmd l')
      vim.cmd('diffthis')

      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(temp_win),
        callback = function()
          vim.schedule(function()
            if temp_file:exists() then temp_file:rm() end
            if vim.api.nvim_buf_is_valid(temp_buf) then
              vim.api.nvim_buf_delete(temp_buf, { force = true })
            end
          end)
        end,
        once = true
      })
    else
      -- File is not tracked by git, just open it normally
      vim.cmd('edit ' .. file_path_str)
    end
  end
end

local function get_changed_files()
  local files = {}
  local git_files = git.list_changed_files()
  local snapshot_base = get_snapshot_dir()

  for file in git_files:gmatch("[^\n]+") do
    local snapshot_file = snapshot_base:joinpath(file)

    if snapshot_file:exists() then
      local cmp_handle = io.popen('cmp -s "' .. file .. '" "' .. tostring(snapshot_file) .. '"; echo $?')
      local cmp_result = cmp_handle:read('*n')
      cmp_handle:close()

      if cmp_result ~= 0 then table.insert(files, { file, snapshot_file }) end
    else
      table.insert(files, { file, nil })
    end
  end

  return files
end

local function revert_file(file_path, snapshot_path)
  if snapshot_path and Path:new(snapshot_path):copy({ destination = file_path, override = true }) then
    return true
  elseif git.is_tracked(file_path) then
    local temp_file = Path:new(vim.fn.tempname())
    if git.get_head_content(file_path, tostring(temp_file)) then
      temp_file:copy { destination = file_path, override = true }
      temp_file:rm()
      return true
    end
  end

  vim.notify("Failed to revert '" .. file_path .. "' - the file is untracked by git.")
  return false
end

M.review = require_git_project(function()
  local files = get_changed_files()

  if #files == 0 then
    vim.notify("No changes to review.")
    return
  end

  if #files == 1 then
    show_diff(files[1][1], files[1][2])
  else
    vim.ui.select(vim.tbl_map(function(f) return f[1] end, files),
      { prompt = "Select a file to review:" },
      function(choice, idx)
        if not choice then return end
        show_diff(files[idx][1], files[idx][2])
      end)
  end
end)

M.set_breakpoint = require_git_project(function()
  local snapshot_base = get_snapshot_dir()

  if snapshot_base:exists() then
    snapshot_base:rm({ recursive = true })
  end

  snapshot_base:mkdir({ parents = true })

  for file in git.list_changed_files():gmatch("[^\n]+") do
    local source_file = Path:new(file)
    local target_file = snapshot_base:joinpath(file)
    target_file:parent():mkdir({ parents = true })
    source_file:copy { destination = target_file }
  end
end, true)

M.revert_all = require_git_project(function()
  local files = get_changed_files()

  if #files == 0 then
    vim.notify("No changes to revert.")
    return
  end

  if vim.fn.input("Revert all " .. #files .. " changed files? (y/n): "):lower() ~= "y" then
    return
  end

  local success_count = 0
  for _, file_data in ipairs(files) do
    if revert_file(file_data[1], file_data[2]) then
      success_count = success_count + 1
    end
  end

  vim.cmd('checktime')
  vim.notify("Reverted " .. success_count .. " of " .. #files .. " files.")
end)

M.revert_current = require_git_project(function()
  local current_file = vim.fn.expand('%:p')
  local rel_path = vim.fn.fnamemodify(current_file, ':.')
  local snapshot_path = get_snapshot_dir():joinpath(rel_path)

  local has_changes = os.execute('git diff --quiet --exit-code "' .. rel_path .. '" > /dev/null 2>&1') ~= 0 or
      os.execute('git ls-files --others --exclude-standard | grep -q "^' ..
        vim.fn.escape(rel_path, '.') .. '$" > /dev/null 2>&1') == 0

  if not has_changes then
    vim.notify("No changes to revert.")
    return
  end

  vim.cmd('update')

  if vim.fn.input("Revert current file? (y/n): "):lower() ~= "y" then
    return
  end

  local has_snapshot = snapshot_path:exists()

  if revert_file(rel_path, has_snapshot and tostring(snapshot_path) or nil) then
    local file = Path:new(rel_path)
    if file:exists() then
      vim.cmd('e!')
    else
      vim.cmd('bdelete!')
    end
  end
end)

M.reset_git_status = function()
  M.__is_git_project = nil
end

return M
