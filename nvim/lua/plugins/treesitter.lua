local configs = require("nvim-treesitter.configs")

vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
vim.opt.foldmethod = "expr"

configs.setup({
  indent = { enable = true },
  highlight = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = false,
      node_incremental = "<CR>",
      node_decremental = "<BS>",
      scope_incremental = false,
    },
  },
  ensure_installed = {
    "c", "cpp", "lua", "vim", "vimdoc", "markdown",
    "html", "css", "javascript", "typescript", "tsx",
    "bash", "haskell", "yaml",
  },
})
