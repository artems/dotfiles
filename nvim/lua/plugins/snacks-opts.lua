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
    win = {
      list = {
        keys = {
          ["<c-c>"] = { "close" },
        },
      },
      input = {
        keys = {
          ["<c-c>"] = { "close", mode = { "n", "i" } },
        },
      },
    },
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
              ["d"] = { "bufdelete", nowait = true },
              ["<c-d>"] = { "bufdelete" },
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
