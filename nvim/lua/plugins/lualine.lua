local function location()
  local line = vim.fn.line('.')
  local column = vim.fn.charcol('.')

  return " " .. string.format('%2d:%-3d', column, line)
end

local format_symbols = {
  dos = '',
  mac = '',
  unix = '',
}

local function file_encoding()
  local format = vim.bo.fileformat
  local encoding = vim.opt.fileencoding:get()
  return format_symbols[format] .. " " .. encoding
end

local function encoding_not_utf_8()
  local format = vim.bo.fileformat
  local encoding = vim.opt.fileencoding:get()
  return format ~= "unix" or (encoding ~= "utf-8" and encoding ~= "")
end

require("lualine").setup({
  options = {
    globalstatus = true,
    always_show_tabline = false,
  },
  tabline = {
    lualine_c = {
      {
        "tabs",
        mode = 2,
        max_length = vim.o.columns,
        show_modified_status = false,
      },
    },
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
