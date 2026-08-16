local PRINT_WIDTH = 80

require("conform").setup({
  formatters_by_ft = {
    markdown = { "prettier" },
  },
  formatters = {
    prettier = {
      prepend_args = { "--prose-wrap", "always", "--print-width", tostring(PRINT_WIDTH) },
    },
  },
})

-- prettier не поддерживает range-форматирование, поэтому conform на gqq/gqip
-- либо ничего не делает, либо форматирует весь файл. Реализуем range сами:
-- берём только строки диапазона, прогоняем их через prettier как отдельный
-- markdown-фрагмент и заменяем только их.
local function format_range(start_lnum, end_lnum)
  local prettier = vim.fn.exepath("prettier")
  if prettier == "" then
    vim.notify("prettier не найден в PATH", vim.log.levels.ERROR)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_lnum - 1, end_lnum, false)
  local input = table.concat(lines, "\n") .. "\n"

  local out = vim.fn.systemlist({
    prettier,
    "--parser", "markdown",
    "--prose-wrap", "always",
    "--print-width", tostring(PRINT_WIDTH),
  }, input)

  if vim.v.shell_error ~= 0 then
    vim.notify("prettier:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  -- prettier добавляет завершающий перевод строки — убираем пустой хвост
  while #out > 0 and out[#out] == "" do
    table.remove(out)
  end

  vim.api.nvim_buf_set_lines(0, start_lnum - 1, end_lnum, false, out)
end

function _G.MarkdownFormatexpr()
  -- В insert/replace formatexpr вызывается при превышении textwidth —
  -- отдаём встроенному переносу, иначе будет дёргать prettier на каждый символ.
  if vim.tbl_contains({ "i", "R", "ic", "ix" }, vim.fn.mode()) then
    return 1
  end

  local start_lnum = vim.v.lnum
  local end_lnum = start_lnum + vim.v.count - 1
  if start_lnum <= 0 or end_lnum < start_lnum then
    return 0
  end

  format_range(start_lnum, end_lnum)
  return 0
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.formatexpr = "v:lua.MarkdownFormatexpr()"
  end,
})
