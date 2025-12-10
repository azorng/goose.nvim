local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, 'GooseBorder', { fg = '#616161' })
  vim.api.nvim_set_hl(0, 'GooseBackground', { link = "Normal" })
end

return M
