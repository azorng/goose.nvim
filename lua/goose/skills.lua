local M = {}

local SKILLS_DIRS = {
  "./.goose/skills",
  "./.claude/skills",
  vim.fn.expand("~/.config/goose/skills"),
  vim.fn.expand("~/.claude/skills"),
}

local function parse_frontmatter(content)
  local lines = vim.split(content, "\n")
  if lines[1] ~= "---" then return nil end

  local frontmatter = {}
  for i = 2, #lines do
    if lines[i] == "---" then break end

    local key, value = lines[i]:match("^(%w+):%s*(.+)")
    if key and value then
      frontmatter[key] = value
    end
  end

  return frontmatter
end

local function read_skill_metadata(skill_dir)
  local skill_file = skill_dir .. "/SKILL.md"
  local fd = vim.loop.fs_open(skill_file, "r", 438)
  if not fd then return nil end

  local stat = vim.loop.fs_fstat(fd)
  if not stat then
    vim.loop.fs_close(fd)
    return nil
  end

  local content = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)

  local frontmatter = parse_frontmatter(content)
  if not frontmatter then return nil end

  return {
    name = frontmatter.name or vim.fn.fnamemodify(skill_dir, ":t"),
    description = frontmatter.description or "",
    path = skill_file
  }
end

local function scan_skills_dir(dir)
  local handle = vim.loop.fs_scandir(dir)
  if not handle then return {} end

  local skills = {}
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    if type == "directory" then
      local metadata = read_skill_metadata(dir .. "/" .. name)
      if metadata then
        table.insert(skills, metadata)
      end
    end
  end

  return skills
end

local function scan_skills()
  local all_skills = {}
  local seen = {}

  for _, dir in ipairs(SKILLS_DIRS) do
    local skills = scan_skills_dir(dir)
    for _, skill in ipairs(skills) do
      if not seen[skill.name] then
        seen[skill.name] = true
        table.insert(all_skills, skill)
      end
    end
  end

  return all_skills
end

function M.select(cb)
  local skills = scan_skills()

  if #skills == 0 then
    vim.notify("No skills found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(skills, {
    prompt = "Select skill:",
    format_item = function(skill)
      return skill.name
    end
  }, cb)
end

return M
