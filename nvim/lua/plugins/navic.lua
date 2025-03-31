local navic = require("nvim-navic")

navic.setup({
  lsp = { auto_attach = true },
  separator = "  ",
  highlight = true,
})

local function attach_navic()
  local bufnr = vim.api.nvim_get_current_buf()

  if navic.is_available(bufnr) then
    return
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if vim.tbl_isempty(clients) then
    return
  end

  local client = clients[1]
  navic.attach(client, bufnr)
end

local enabled = false
local function toggle_navic()
  enabled = not enabled
  if enabled then
    attach_navic()
    vim.o.winbar = "%{%v:lua.require('nvim-navic').get_location()%}"
  else
    vim.o.winbar = nil
  end
end

vim.keymap.set('n', '<leader>tn', toggle_navic, { desc = "Toggle Navic", silent = true })
