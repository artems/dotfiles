local snacks = require('snacks')

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    snacks.toggle.option("wrap", { name = "wrap" }):map("yow")
    snacks.toggle.option("paste", { name = "paste" }):map("yop")
    snacks.toggle.option("spell", { name = "spelling" }):map("yoz")
  end,
})

local function remove_quotes(str)
  if str:match('^".*"$') or str:match("^'.*'$") then
    return str:sub(2, -2)
  end
  return str
end

vim.api.nvim_create_user_command('Gr', function(opts)
  if opts.args == "" then
    snacks.picker.grep()
  else
    snacks.picker.grep({ focus = "list", search = remove_quotes(opts.args) })
  end
end, { nargs = "*", desc = 'Search using Snacks.picker.grep()' })
