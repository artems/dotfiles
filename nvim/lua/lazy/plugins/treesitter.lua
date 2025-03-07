local configs = require("nvim-treesitter.configs")

configs.setup({
  indent = { enable = true },
  highlight = { enable = true },
  ensure_installed = {
    "c", "cpp", "lua", "vim", "vimdoc", "query", "markdown",
    "html", "css", "javascript", "typescript", "tsx",
    "haskell", "yaml",
  },
})
