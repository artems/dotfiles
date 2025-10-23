local navic = require("nvim-navic")
local devicons = require("nvim-web-devicons")

local separator = "  "

-- Функция для расчета видимой длины строки (без учета highlight-кодов)
local function calculate_display_width(str)
  -- Убираем highlight-коды: %#HighlightGroup#, %*, %{...%}
  local visible = str:gsub('%%#[^#]+#', '')  -- %#HighlightGroup#
  visible = visible:gsub('%%%-?%d*%*', '')    -- %* или %-*
  visible = visible:gsub('%%{[^}]*%%}', '')   -- %{...%}
  return vim.fn.strdisplaywidth(visible)
end

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

  if navic_location == '' then
    return file_path
  end

  -- Получаем ширину окна (оставляем небольшой резерв)
  local win_width = vim.api.nvim_win_get_width(0) - 4
  local full_winbar = file_path .. separator .. navic_location

  -- Если влезает - возвращаем как есть
  if calculate_display_width(full_winbar) <= win_width then
    return full_winbar
  end

  -- Разбиваем navic_location на элементы
  local navic_parts = vim.split(navic_location, separator, { plain = true })

  -- Если в navic_location только один элемент - возвращаем как есть
  if #navic_parts <= 1 then
    return full_winbar
  end

  -- Пробуем убирать элементы справа налево, оставляя последний
  local ellipsis = '…'
  for i = #navic_parts - 1, 1, -1 do
    -- Оставляем элементы с начала до (i-1), добавляем ..., затем последний элемент
    local truncated_parts = {}

    -- Берем элементы до текущей позиции
    for j = 1, i - 1 do
      table.insert(truncated_parts, navic_parts[j])
    end

    -- Добавляем многоточие
    table.insert(truncated_parts, ellipsis)

    -- Добавляем последний элемент
    table.insert(truncated_parts, navic_parts[#navic_parts])

    local truncated_location = table.concat(truncated_parts, separator)
    local result = file_path .. separator .. truncated_location

    if calculate_display_width(result) <= win_width then
      return result
    end
  end

  -- Если даже с одним элементом не влезает - оставляем только последний элемент
  local minimal_location = ellipsis .. separator .. navic_parts[#navic_parts]
  return file_path .. separator .. minimal_location
end

local enabled = true

local function show_navic_if_enable()
  if vim.bo.buftype == "terminal" then
    return
  end

  if enabled and vim.wo.winbar and vim.wo.diff then
    vim.wo.winbar = nil
    return
  end

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

navic.setup({
  lsp = { auto_attach = true },
  separator = separator,
  highlight = true,
})

vim.api.nvim_create_augroup("vimrc_navic_update", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = "vimrc_navic_update",
  callback = show_navic_if_enable
})

vim.api.nvim_create_autocmd("OptionSet", {
  group = "vimrc_navic_update",
  pattern = "diff",
  callback = show_navic_if_enable
})

vim.keymap.set('n', '<leader>tn', toggle_navic, { desc = "Toggle Navic", silent = true })
