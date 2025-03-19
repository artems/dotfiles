local function file_lines()
  local line = vim.fn.line('.')
  local line_count = vim.api.nvim_buf_line_count(0)
  return " " .. string.format('%3d:%d', line, line_count)
end

local function file_column()
  return " " .. string.format('%2d', vim.fn.charcol('.'))
end

local format_symbols = {
  unix = '', -- e712
  dos = '', -- e70f
  mac = '', -- e711
}

local function file_encoding()
  local format = vim.bo.fileformat
  local encoding = vim.opt.fileencoding:get()
  return format_symbols[format] .. "  " .. encoding
end

require("lualine").setup({
  options = {
    globalstatus = true,
    always_show_tabline = false,
  },
  tabline = {
    lualine_a = { { "tabs", mode = 1, show_modified_status = false } },
  },
  sections = {
    lualine_c = {
      {
        "filename",
        symbols = {
          modified = '󰏫',
          readonly = '󰌾',
          unnamed = '[No Name]',
          newfile = '[New file]',
        },
      },
      {
        "navic",
        color_correction = "static",
        padding = { left = 1, right = 0 },
      },
    },
    lualine_x = { file_encoding, "filetype" },
    lualine_y = { "progress", file_column },
    lualine_z = { file_lines },
  },
})
