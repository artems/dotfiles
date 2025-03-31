local gitsigns = require("gitsigns")

gitsigns.setup({
  on_attach = function(bufnr)
    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, { buffer = bufnr, desc = "Jump to next git change" })

    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, { buffer = bufnr, desc = "Jump to previous git change" })

    vim.keymap.set("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { buffer = bufnr,  desc = "Git stage hunk" })
    vim.keymap.set("v", "<leader>hr", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { buffer = bufnr, desc = "Git reset hunk" })

    vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buffer = bufnr,  desc = "Git stage hunk" })
    vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr,  desc = "Git reset hunk" })
    vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer, { buffer = bufnr,  desc = "Git stage buffer" })
    vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { buffer = bufnr,  desc = "Git reset buffer" })
    vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr,  desc = "Git preview hunk" })
    vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { buffer = bufnr, desc = "Git diff against index" })
    vim.keymap.set("n", "<leader>hb", gitsigns.blame_line, { buffer = bufnr,  desc = "Git blame line" })

    vim.keymap.set("n", "<leader>td", gitsigns.toggle_deleted, { buffer = bufnr,  desc = "Toggle show deleted" })
    vim.keymap.set("n", "<leader>tw", gitsigns.toggle_word_diff, { buffer = bufnr,  desc = "Toggle show word diff" })
    vim.keymap.set("n", "<leader>tb", gitsigns.toggle_current_line_blame, { buffer = bufnr,  desc = "Toggle show blame line" })
  end
})
