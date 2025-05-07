local navic = require("nvim-navic")
local devicons = require("nvim-web-devicons")

navic.setup({
  lsp = { auto_attach = true },
  separator = "  ",
  highlight = true,
})

_G.get_navic_winbar = function()
  local path = vim.fn.expand('%:p:.')
  local parts = {}
  local components = {}

  for part in path:gmatch('[^/]+') do
    table.insert(parts, part)
  end

  if #parts == 0 then
    return '[No Name]'
  end

  for i, part in ipairs(parts) do
    local icon, icon_hl, component

    if i < #parts then
      icon = ""
      icon_hl = "DevIconDefault"
    else
      local extension = vim.fn.fnamemodify(part, ':e')
      icon, icon_hl = devicons.get_icon(part, extension, { default = true })
    end

    if icon_hl then
      component = string.format('%%#%s#%s%%* %s', icon_hl, icon, part)
    else
      component = icon .. ' ' .. part
    end

    table.insert(components, component)
  end

  local file_path = table.concat(components, '  ')
  local navic_location = navic.get_location()

  if navic_location ~= '' then
    return file_path .. '  ' .. navic_location
  end

  return file_path
end

local enabled = true

local function show_navic_if_enable()
  if enabled and vim.bo.buftype == "" and vim.fn.expand('%') ~= '' then
    vim.wo.winbar = "%{%v:lua.get_navic_winbar()%}"
  else
    vim.wo.winbar = nil
  end
end

local function toggle_navic()
  enabled = not enabled
  show_navic_if_enable()
end

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = show_navic_if_enable
})

vim.keymap.set('n', '<leader>tn', toggle_navic, { desc = "Toggle Navic", silent = true })
