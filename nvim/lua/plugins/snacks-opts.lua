return {
  bigfile = {
    enabled = true,
  },
  dashboard = {
    enabled = true,
  },
  explorer = {
    enabled = true,
  },
  indent = {
    enabled = true,
    animate = { enabled = false },
  },
  input = {
    enabled = true,
  },
  notifier = {
    enabled = true,
  },
  picker = {
    enabled = true,
    sources = {
      recent = {
        filter = {
          filter = function(item)
            return string.sub(item.file, -1) ~= "/"
          end
        }
      },
      select = {
        focus = "list"
      },
      buffers = {
        win = {
          list = {
            keys = {
              ["d"] = { "bufdelete" },
              ["<c-d>"] = { "bufdelete" },
              ["<c-c>"] = { "close", mode = { "n", "i" } },
            },
          },
          input = {
            keys = {
              ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
            },
          },
        },
        focus = "list",
        sort_lastused = false,
      },
      explorer = {
        layout = { preset = "dropdown" },
        auto_close = true
      },
    },
    formatters = {
      file = {
        filename_first = true,
      },
    },
  },
  rename = { enabled = true },
  scroll = {
    enabled = true,
    animate = {
      easing = "outSine",
      duration = { total = 200 },
    },
  },
  statuscolumn = { enabled = true },
  terminal = { enabled = true },
  words = { enabled = true },
}
