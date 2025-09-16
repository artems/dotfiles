return {
  bigfile = {
    enabled = true,
    setup = function(ctx)
      vim.b[ctx.buf].snacks_indent = false
      vim.b[ctx.buf].snacks_scroll = false

      require('snacks').util.wo(0, {
        wrap = false,
        foldmethod = "manual",
        statuscolumn = "",
        conceallevel = 0,
      })

      if vim.fn.exists(":NoMatchParen") ~= 0 then
        vim.cmd("NoMatchParen")
      end

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ctx.buf) then
          vim.bo[ctx.buf].syntax = ctx.ft
        end
      end)
    end,
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
    filter = function(buf)
      return vim.g.snacks_indent ~= false and
        vim.b[buf].snacks_indent ~= false and
        vim.bo[buf].filetype ~= "markdown" and
        vim.bo[buf].buftype == ""
    end,
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
          ["D"] = { "inspect" },
          ["F"] = { "toggle_follow" },
          ["H"] = { "toggle_hidden" },
          ["I"] = { "toggle_ignored" },
          ["M"] = { "toggle_maximize" },
          ["P"] = { "toggle_preview" },
          ["<a-d>"] = false,
          ["<a-f>"] = false,
          ["<a-h>"] = false,
          ["<a-i>"] = false,
          ["<a-m>"] = false,
          ["<a-p>"] = false,
        },
      },
      input = {
        keys = {
          ["<c-c>"] = { "close", mode = { "n", "i" } },
          ["<a-d>"] = false,
          ["<a-f>"] = false,
          ["<a-h>"] = false,
          ["<a-i>"] = false,
          ["<a-m>"] = false,
          ["<a-p>"] = false,
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
        focus = "list",
        layout = { hidden = { "input" } },
      },
      buffers = {
        win = {
          list = {
            keys = {
              ["d"] = { "bufdelete", nowait = true },
              ["dd"] = false,
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
        sort_lastused = true,
      },
      explorer = {
        layout = {
          preset = "dropdown",
          layout = {
            backdrop = true,
          },
        },
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
