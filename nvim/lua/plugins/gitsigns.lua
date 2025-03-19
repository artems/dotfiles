local gitsigns = require("gitsigns")

gitsigns.setup({
  on_attach = function(bufnr)
    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, { buffer = bufnr, desc = "jump to next git [c]hange" })

    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, { buffer = bufnr, desc = "jump to previous git [c]hange" })

    vim.keymap.set("v", "<leader>hs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { buffer = bufnr,  desc = "git [s]tage hunk" })
    vim.keymap.set("v", "<leader>hr", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, { buffer = bufnr, desc = "git [r]eset hunk" })
    ---
    vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { buffer = bufnr,  desc = "git [s]tage hunk" })
    vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr,  desc = "git [r]eset hunk" })
    vim.keymap.set("n", "<leader>hS", gitsigns.stage_buffer, { buffer = bufnr,  desc = "git [S]tage buffer" })
    vim.keymap.set("n", "<leader>hR", gitsigns.reset_buffer, { buffer = bufnr,  desc = "git [R]eset buffer" })
    vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr,  desc = "git [p]review hunk" })
    vim.keymap.set("n", "<leader>hi", gitsigns.preview_hunk_inline, { buffer = bufnr,  desc = "git preview hunk [i]nline" })
    vim.keymap.set("n", "<leader>hd", gitsigns.diffthis, { buffer = bufnr, desc = "git [d]iff against index" })
    vim.keymap.set("n", "<leader>hb", gitsigns.blame_line, { buffer = bufnr,  desc = "git [b]lame line" })

    vim.keymap.set("n", "<leader>td", gitsigns.toggle_deleted, { buffer = bufnr,  desc = "[t]oggle git show [d]eleted" })
    vim.keymap.set("n", "<leader>tw", gitsigns.toggle_word_diff, { buffer = bufnr,  desc = "[t]oggle git show [w]ord diff" })
    vim.keymap.set("n", "<leader>tb", gitsigns.toggle_current_line_blame, { buffer = bufnr,  desc = "[t]oggle git show [b]lame line" })
  end
})
