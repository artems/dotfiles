local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local actions_layout = require("telescope.actions.layout")

local function multiopen(prompt_bufnr, open_cmd)
  local actions_state = require("telescope.actions.state")
  local picker = actions_state.get_current_picker(prompt_bufnr)
  local multi_selection = picker:get_multi_selection()

  if not vim.tbl_isempty(multi_selection) then
    actions.close(prompt_bufnr)
    for _, file in pairs(multi_selection) do
      if file.path ~= nil then
        vim.cmd(string.format("%s %s", open_cmd, file.path))
      end
    end
  else
    actions.select_default(prompt_bufnr)
  end
end

local function multiopen_buf(prompt_bufnr)
  multiopen(prompt_bufnr, "edit")
end

local function multiopen_tab(prompt_bufnr)
  multiopen(prompt_bufnr, "tabe")
end

local function multiopen_split(prompt_bufnr)
  multiopen(prompt_bufnr, "split")
end

local function multiopen_vsplit(prompt_bufnr)
  multiopen(prompt_bufnr, "vsplit")
end

require("telescope").setup({
  defaults = {
    path_display = { truncate = true },
    scroll_strategy = "limit",
    layout_config = {
      prompt_position = "top",
    },
    sorting_strategy = "ascending",
    mappings = {
      i = {
        ["<CR>"] = multiopen_buf,
        ["<Esc>"] = actions.close,
        ["<C-t>"] = multiopen_tab,
        ["<C-s>"] = multiopen_split,
        ["<C-v>"] = multiopen_vsplit,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-f>"] = actions.preview_scrolling_down,
        ["<C-b>"] = actions.preview_scrolling_up,
        ["<C-h>"] = actions_layout.toggle_preview,
      },
      n = {
        ["<C-h>"] = actions_layout.toggle_preview,
      }
    },
    multi_icon = "•",
    entry_prefix = "  ",
    prompt_prefix = " ",
    selection_caret = "❯ ",
  },
  pickers = {
    buffers = {
      sort_mru = true,
      mappings = {
        i = {
          ["<C-d>"] = actions.delete_buffer,
        }
      }
    }
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown(),
    }
  },
})

require("telescope").load_extension("ui-select")
require("telescope").load_extension("fzy_native")

vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[s]earch [f]iles" })
vim.keymap.set("n", "<leader>sr", builtin.oldfiles, { desc = "[s]earch [r]ecent files" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[s]earch using [g]rep" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[s]earch for [w]ord under cursor" })
vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[s]earch [b]uffers" })
vim.keymap.set("n", "<leader>se", builtin.symbols, { desc = "[s]earch [e]moji" })
vim.keymap.set("n", "<leader>ss", builtin.resume, { desc = "[s]earch re[s]ume" })
vim.keymap.set("n", "<leader>s/", function()
  builtin.live_grep({
    prompt_title = "Live Grep in Open Files",
    grep_open_files = true,
  })
end, { desc = "[s]earch [/] in open files" })
