require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<C-e>"] = { "cancel" },
    ["<C-y>"] = { "select_and_accept" },
    ["<C-p>"] = { "show", "select_prev" },
    ["<C-n>"] = { "show", "select_next" },
    ["<C-b>"] = { "scroll_documentation_up" },
    ["<C-u>"] = { "scroll_documentation_up" },
    ["<C-f>"] = { "scroll_documentation_down" },
    ["<C-d>"] = { "scroll_documentation_down" },
    ["<C-k>"] = {
      "show_documentation",
      "hide_documentation",
    },
    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },
  cmdline = { enabled = false },
  completion = {
    menu = { auto_show = false, draw = { treesitter = { "lsp" } } },
    list = { selection = { preselect = false, auto_insert = true } },
    accept = { auto_brackets = { enabled = false } },
    keyword = { range = "prefix" },
  },
  sources = {
    providers = {
      lsp = {
        -- show buffer completions with LSP
        fallbacks = {},
      },
      path = {
        opts = {
          trailing_slash = false,
          label_trailing_slash = false,
        },
      },
    }
  },
})
