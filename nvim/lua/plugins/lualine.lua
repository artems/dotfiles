local devicons = require("nvim-web-devicons")

local function location()
  local line = vim.fn.line(".")
  local column = vim.fn.charcol(".")

  return " " .. string.format("%2d:%-3d", column, line)
end

local format_symbols = {
  dos = "",
  mac = "",
  unix = "",
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

-- Branch and diff come from gitsigns rather than lualine's own git support,
-- which only knows how to find a .git directory. With arcsigns in place
-- gitsigns fills these in for arc working copies too.
local function vcs_branch()
  return vim.b.gitsigns_head or vim.g.gitsigns_head or ""
end

local function vcs_diff()
  local status = vim.b.gitsigns_status_dict
  if not status then
    return nil
  end

  return {
    added = status.added,
    modified = status.changed,
    removed = status.removed,
  }
end

local function tab_format(name, context)
  local extension = vim.fn.fnamemodify(name, ":e")
  local icon = devicons.get_icon(name, extension, { default = true })

  return tostring(context.tabnr) .. ": " .. icon .. " " .. name
end

require("lualine").setup({
  options = {
    globalstatus = vim.o.laststatus == 3,
    always_show_tabline = vim.o.showtabline == 2,
    disabled_filetypes = {
      statusline = {
        "dashboard",
        "snacks_dashboard",
      },
    },
  },
  tabline = {
    lualine_a = {
      {
        "tabs",
        mode = 1,
        max_length = vim.o.columns,
        show_modified_status = false,
        fmt = tab_format,
      },
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      { vcs_branch, icon = "" },
      { "diff", source = vcs_diff },
    },
    lualine_c = {
      {
        "filename",
        path = 0,
        symbols = {
          modified = "󰏫",
          readonly = "󰌾",
          unnamed = "[No Name]",
          newfile = "[New file]",
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
