local surround = require('nvim-surround')

local opts = { move_cursor = "sticky" }

vim.api.nvim_create_augroup("vimrc_nvim_surround", { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = "vimrc_nvim_surround",
  pattern = '*',
  callback = function()
    local filetype = vim.bo.filetype
    if filetype == 'snacks_picker_list' or filetype == 'snacks_picker_input' then
      return
    end

    surround.setup(vim.tbl_deep_extend("keep", opts, { buffer = 0 }))
  end,
})
