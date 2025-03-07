local actions = require("telescope.actions")

local function multiopen(prompt_bufnr, open_cmd)
  local actions_state = require("telescope.actions.state")
  local picker = actions_state.get_current_picker(prompt_bufnr)
  local multi_selection = picker:get_multi_selection()
  if not vim.tbl_isempty(multi_selection) then
    actions.close(prompt_bufnr)
    for _, file in pairs(multi_selection) do
      if file.path ~= nil then
        vim.cmd(string.format('%s %s', open_cmd, file.path))
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

return {
  defaults = {
    mappings = {
      i = {
        ["<CR>"] = multiopen_buf,
        ["<C-t>"] = multiopen_tab,
        ["<C-s>"] = multiopen_split,
        ["<C-v>"] = multiopen_vsplit,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  },
}
