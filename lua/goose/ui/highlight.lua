local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, 'GooseBorder', { fg = '#616161' })
  vim.api.nvim_set_hl(0, 'GooseBackground', {})
  vim.api.nvim_set_hl(0, 'GooseSessionDescription', {
    -- bg = '#212121',
    fg = '#757575',
    bold = false,
  })
end

return M
