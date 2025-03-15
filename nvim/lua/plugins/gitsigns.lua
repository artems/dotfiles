local gitsigns = require('gitsigns')

gitsigns.setup({
  on_attach = function(bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "]h", gitsigns.next_hunk, opts)
    vim.keymap.set("n", "[h", gitsigns.prev_hunk, opts)
    vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, opts)
    vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, opts)
    vim.keymap.set("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, opts)
    vim.keymap.set("v", "<leader>hr", function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, opts)
    vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, opts)
    vim.keymap.set("n", "<leader>hi", gitsigns.preview_hunk_inline, opts)
    vim.keymap.set("n", "<leader>hb", function()
      gitsigns.blame_line({ full = true })
    end, opts)
    vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, opts)
  end
})
