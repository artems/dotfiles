return {
  bigfile = {
    enabled = true,
    size = 1024 * 1024, -- 1MB
    line_length = 1024,
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

      -- Disable LSP for large files
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ctx.buf) then
          vim.bo[ctx.buf].syntax = ctx.ft

          -- Detach all LSP clients from this buffer
          local clients = vim.lsp.get_clients({ bufnr = ctx.buf })
          for _, client in ipairs(clients) do
            vim.lsp.buf_detach_client(ctx.buf, client.id)
          end
        end
      end)
    end,
  },
  bufdelete = {
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
    actions = {
      bufdelete_stable = function(picker)
        if #picker.list.items <= 1 then
          Snacks.notify.warn("Cannot delete the last buffer", { title = "Snacks Picker" })
          return
        end

        picker.preview:reset()

        local non_buf = false
        local selected = picker:selected({ fallback = true })

        for _, item in ipairs(selected) do
          if item.buf then
            Snacks.bufdelete.delete(item.buf)

            -- Remove the deleted buffer from list.items
            local new_items = {}
            for _, li in ipairs(picker.list.items) do
              if li.buf ~= item.buf then
                new_items[#new_items + 1] = li
              end
            end
            picker.list.items = new_items

            -- Rebuild topk only if it was non-empty.
            -- When empty, the matcher used the fast path and list:get falls back
            -- to items[i] directly. Populating topk would switch rendering to
            -- topk order (sorted by picker.sort), reordering the list.
            if picker.list.topk:get(1) ~= nil then
              picker.list.topk:clear()
              for _, li in ipairs(picker.list.items) do
                picker.list.topk:add(li)
              end
            end

            -- Sync finder.items so that picker:count() stays accurate
            local new_finder = {}
            for _, fi in ipairs(picker.finder.items) do
              if fi.buf ~= item.buf then
                new_finder[#new_finder + 1] = fi
              end
            end
            picker.finder.items = new_finder
          else
            non_buf = true
          end
        end

        if non_buf then
          Snacks.notify.warn("Only open buffers can be deleted", { title = "Snacks Picker" })
        end

        -- Clamp cursor if it went past the end of the list
        local total = #picker.list.items
        if picker.list.cursor > total then
          picker.list.cursor = math.max(1, total)
        end

        -- Clear selection and re-render
        picker.list:set_selected()
        picker.list.dirty = true
        picker.list:update()
      end,
    },
    win = {
      list = {
        keys = {
          ["D"] = { "inspect" },
          ["F"] = { "toggle_follow" },
          ["H"] = { "toggle_hidden" },
          ["I"] = { "toggle_ignored" },
          ["M"] = { "toggle_maximize" },
          ["P"] = { "toggle_preview" },
          ["<c-c>"] = { "close" },
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
      },
      buffers = {
        win = {
          list = {
            keys = {
              ["d"] = { "bufdelete_stable" },
              ["dd"] = false,
              ["<c-d>"] = { "bufdelete_stable" },
            },
          },
          input = {
            keys = {
              ["<c-d>"] = { "bufdelete_stable", mode = { "n", "i" } },
            },
          },
        },
        focus = "list",
        layout = { preview = false },
        on_show = function(picker)
          local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
          local buf = vim.api.nvim_win_get_buf(prev_win)
          local pos = vim.api.nvim_win_get_cursor(prev_win)

          vim.api.nvim_buf_set_mark(buf, '"', pos[1], pos[2], {})
          picker:refresh()
        end,
        sort_lastused = true,
      },
      explorer = {
        win = {
          list = {
            keys = {
              [ "<C-h>" ] = "tcd",
              [ "<C-c>" ] = "close",
            },
          },
        },
        layout = {
          preset = "dropdown",
          layout = {
            backdrop = true,
          },
        },
        hidden = true,
        ignored = true,
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
  terminal = {
    enabled = true,
    auto_insert = false,
    win = { height = 0.5 },
  },
  words = { enabled = true },
}
