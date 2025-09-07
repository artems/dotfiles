require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<C-e>"] = { "cancel" },
    ["<C-y>"] = { "select_and_accept" },
    ["<C-p>"] = { "show", "select_prev" },
    ["<C-n>"] = { "show", "select_next" },
    ["<C-b>"] = { "scroll_documentation_up" },
    ["<C-f>"] = { "scroll_documentation_down" },
    ["<C-k>"] = {
      "show_documentation",
      "hide_documentation",
    },
    ['<Tab>'] = { 'accept', 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },
  cmdline = {
    enabled = true,
    keymap = {
      ['<Tab>'] = { 'show', 'accept' },
    },
    completion = {
      menu = {
        auto_show = function()
          return vim.fn.getcmdtype() == ':'
        end,
      },
    },
  },
  signature = { enabled = true },
  appearance = { nerd_font_variant = "normal" },
  completion = {
    menu = { auto_show = false, draw = { treesitter = { "lsp" } } },
    list = { selection = { preselect = true, auto_insert = false } },
    accept = { auto_brackets = { enabled = false } },
    trigger = { show_on_keyword = true },
    keyword = { range = "prefix" },
    ghost_text = { enabled = true },
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
