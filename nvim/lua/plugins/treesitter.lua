vim.opt.foldenable = true
vim.opt.foldmethod = "expr"
vim.opt.foldlevelstart = 10

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'c', 'cpp', 'bash', 'diff',
    'lua', 'luadoc', 'vim', 'vimdoc',
    'json', 'yaml', 'markdown', 'markdown_inline',
    'html', 'css', 'javascript', 'typescript',
  },
  callback = function()
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()

    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
