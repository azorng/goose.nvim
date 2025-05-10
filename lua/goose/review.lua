local Path = require('plenary.path')
local M = {}

-- State variables for diff navigation
M.__changed_files = nil
M.__current_file_index = nil
M.__diff_tab = nil -- Track the diff tab ID

-- Git helpers
local git = {
  is_project = function()
    if M.__is_git_project ~= nil then
      return M.__is_git_project
    end

    local git_dir = Path:new(vim.fn.getcwd()):joinpath('.git')
    M.__is_git_project = git_dir:exists() and git_dir:is_dir()
    return M.__is_git_project
  end,

  list_changed_files = function()
    local result = vim.fn.system('git ls-files -m -o --exclude-standard')
    return result
  end,

  is_tracked = function(file_path)
    local success = os.execute('git ls-files --error-unmatch "' .. file_path .. '" > /dev/null 2>&1')
    return success == 0
  end,

  get_head_content = function(file_path, output_path)
    local success = os.execute('git show HEAD:"' .. file_path .. '" > "' .. output_path .. '" 2>/dev/null')
    return success == 0
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

-- Helper function to revert a file
local function revert_file(file_path, snapshot_path)
  if snapshot_path then
    Path:new(snapshot_path):copy({ destination = file_path, override = true })
  elseif git.is_tracked(file_path) then
    local temp_file = Path:new(vim.fn.tempname())
    if git.get_head_content(file_path, tostring(temp_file)) then
      -- Use explicit parentheses for function call
      temp_file:copy({ destination = file_path, override = true })
      temp_file:rm()
    end
  else
    -- File not tracked - remove and close buffer
    local absolute_path = vim.fn.fnamemodify(file_path, ":p")
    local bufnr = vim.fn.bufnr(absolute_path)
    if bufnr ~= -1 then
      vim.api.nvim_command('silent! bdelete! ' .. bufnr)
    end
    Path:new(file_path):rm()
  end

  vim.cmd('checktime')
  return true
end

local function close_diff_tab()
  if M.__diff_tab and vim.api.nvim_tabpage_is_valid(M.__diff_tab) then
    -- Clean up the autocommand group for this tab
    pcall(vim.api.nvim_del_augroup_by_name, "GooseDiffCleanup" .. M.__diff_tab)

    -- Get all windows in the diff tab
    local windows = vim.api.nvim_tabpage_list_wins(M.__diff_tab)

    -- Store the buffer numbers before closing the tab
    local buffers = {}
    for _, win in ipairs(windows) do
      local buf = vim.api.nvim_win_get_buf(win)
      table.insert(buffers, buf)
    end

    -- Switch to diff tab and close it
    vim.api.nvim_set_current_tabpage(M.__diff_tab)
    pcall(vim.cmd, 'tabclose')

    -- Now close all buffers that were in the diff tab
    -- Use pcall to safely handle any errors
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        -- Only close the buffer if it's not visible in any window
        local visible = false
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            visible = true
            break
          end
        end

        if not visible then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end
  M.__diff_tab = nil
end

local function files_are_different(file1, file2)
  local result = vim.fn.system('cmp -s "' .. file1 .. '" "' .. file2 .. '"; echo $?')
  return tonumber(result) ~= 0
end

local function get_changed_files()
  local files = {}
  local git_files = git.list_changed_files()
  local snapshot_base = get_snapshot_dir()

  for file in git_files:gmatch("[^\n]+") do
    local snapshot_file = snapshot_base:joinpath(file)

    if snapshot_file:exists() then
      if files_are_different(file, tostring(snapshot_file)) then
        table.insert(files, { file, tostring(snapshot_file) })
      end
    else
      table.insert(files, { file, nil })
    end
  end

  M.__changed_files = files
  return files
end

-- Show a diff between file and its reference (snapshot or HEAD)
local function show_file_diff(file_path, snapshot_path)
  -- First close any existing diff tab
  close_diff_tab()

  -- Create new tab for diffing
  vim.cmd('tabnew')
  M.__diff_tab = vim.api.nvim_get_current_tabpage()

  -- Close tab on any split window close
  local augroup = vim.api.nvim_create_augroup("GooseDiffCleanup" .. M.__diff_tab, { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function(event)
      if M.__diff_tab and vim.api.nvim_tabpage_is_valid(M.__diff_tab) then
        close_diff_tab()
      end
    end
  })

  if snapshot_path then
    -- Compare with snapshot file (maintain original positions)
    vim.cmd('edit ' .. snapshot_path)
    vim.cmd('setlocal readonly buftype=nofile nomodifiable')
    vim.cmd('diffthis')

    vim.cmd('vsplit ' .. file_path)
    vim.cmd('diffthis')

    -- Focus on right side (current file)
    -- which is already where we are after vsplit
  else
    -- If file is tracked by git, compare with HEAD, otherwise just open it
    if git.is_tracked(file_path) then
      -- Create a temporary file from the HEAD version
      local temp_file = vim.fn.tempname()
      if git.get_head_content(file_path, temp_file) then
        -- First edit the current file
        vim.cmd('edit ' .. file_path)
        local file_type = vim.bo.filetype

        -- Then split with HEAD version on the left
        vim.cmd('leftabove vsplit ' .. temp_file)
        vim.cmd('setlocal readonly buftype=nofile nomodifiable filetype=' .. file_type)
        vim.cmd('diffthis')

        -- Go back to current file window and enable diff there
        vim.cmd('wincmd l')
        vim.cmd('diffthis')
      else
        -- File is not tracked by git, just open it
        vim.cmd('edit ' .. file_path)
      end
    else
      -- File is not tracked by git, just open it
      vim.cmd('edit ' .. file_path)
    end
  end
end

-- Public functions

-- Review the changes in a file
M.review = require_git_project(function()
  local files = get_changed_files()

  if #files == 0 then
    vim.notify("No changes to review.")
    return
  end

  if #files == 1 then
    M.__current_file_index = 1
    show_file_diff(files[1][1], files[1][2])
  else
    vim.ui.select(vim.tbl_map(function(f) return f[1] end, files),
      { prompt = "Select a file to review:" },
      function(choice, idx)
        if not choice then return end
        M.__current_file_index = idx
        show_file_diff(files[idx][1], files[idx][2])
      end)
  end
end)

-- Navigate to the next file diff
M.next_diff = require_git_project(function()
  -- If no cached files or we're at the end, refresh the list
  if not M.__changed_files or not M.__current_file_index or M.__current_file_index >= #M.__changed_files then
    local files = get_changed_files()
    if #files == 0 then
      vim.notify("No changes to review.")
      return
    end
    M.__current_file_index = 1
  else
    M.__current_file_index = M.__current_file_index + 1
  end

  local idx = M.__current_file_index
  local file_data = M.__changed_files[idx]
  vim.notify(string.format("Showing file %d of %d: %s", idx, #M.__changed_files, file_data[1]))
  show_file_diff(file_data[1], file_data[2])
end)

-- Navigate to the previous file diff
M.prev_diff = require_git_project(function()
  -- If no cached files, refresh the list
  if not M.__changed_files or #M.__changed_files == 0 then
    local files = get_changed_files()
    if #files == 0 then
      vim.notify("No changes to review.")
      return
    end
    M.__current_file_index = #files
  else
    -- If we're at the beginning or no current index, go to the end
    if not M.__current_file_index or M.__current_file_index <= 1 then
      M.__current_file_index = #M.__changed_files
    else
      M.__current_file_index = M.__current_file_index - 1
    end
  end

  local idx = M.__current_file_index
  local file_data = M.__changed_files[idx]
  vim.notify(string.format("Showing file %d of %d: %s", idx, #M.__changed_files, file_data[1]))
  show_file_diff(file_data[1], file_data[2])
end)

-- Close the diff view completely
M.close_diff = function()
  close_diff_tab()
end

-- Set a snapshot of the current state for future comparison
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
    source_file:copy({ destination = target_file })
  end
end, true)

-- Revert all changes since the last snapshot
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

  vim.notify("Reverted " .. success_count .. " of " .. #files .. " files.")
end)

-- Revert changes in the current file
M.revert_current = require_git_project(function()
  local files = get_changed_files()
  local current_file = vim.fn.expand('%:p')
  local rel_path = vim.fn.fnamemodify(current_file, ':.')

  local changed_file = nil
  for _, file_data in ipairs(files) do
    if file_data[1] == rel_path then
      changed_file = file_data
      break
    end
  end

  if not changed_file then
    vim.notify("No changes to revert.")
    return
  end

  if vim.fn.input("Revert current file? (y/n): "):lower() ~= "y" then
    return
  end

  if revert_file(changed_file[1], changed_file[2]) then
    vim.cmd('e!')
  end
end)

-- Reset the git project status cache
M.reset_git_status = function()
  M.__is_git_project = nil
end

return M
