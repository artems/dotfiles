local function location()
  local line = vim.fn.line('.')
  local column = vim.fn.charcol('.')

  return " " .. string.format('%3d:%-2d', column, line)
end

local format_symbols = {
  unix = '',
  dos = '',
  mac = '',
}

local function file_encoding()
  local format = vim.bo.fileformat
  local encoding = vim.opt.fileencoding:get()
  return format_symbols[format] .. " " .. encoding
end

local function encoding_not_utf_8()
  local format = vim.bo.fileformat
  local encoding = vim.opt.fileencoding:get()
  return encoding and (format ~= "unix" or encoding ~= "utf-8")
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
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
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
    },
    lualine_x = {
      "diagnostics",
      { file_encoding, cond = encoding_not_utf_8 },
      "filetype",
    },
    lualine_y = { "progress" },
    lualine_z = { location },
  },
})
