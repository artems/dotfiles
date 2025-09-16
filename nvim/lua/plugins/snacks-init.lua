local snacks = require('snacks')

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    snacks.toggle.option("wrap", { name = "wrap" }):map("yow")
    snacks.toggle.option("paste", { name = "paste" }):map("yop")
    snacks.toggle.option("spell", { name = "spelling" }):map("yoz")
  end,
})
