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
      "filename",
      {
        "navic",
        color_correction = "static",
        padding = { left = 1, right = 0 },
      },
    },
    lualine_x = { "encoding", "filetype" },
  },
})
