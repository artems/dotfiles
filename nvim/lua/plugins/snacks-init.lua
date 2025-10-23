local snacks = require('snacks')

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    snacks.toggle.option("wrap", { name = "wrap" }):map("yow")
    snacks.toggle.option("paste", { name = "paste" }):map("yop")
    snacks.toggle.option("spell", { name = "spelling" }):map("yoz")
  end,
})

local function parse_args(str)
  local args = {}
  local current = ""
  local in_quotes = false
  local quote_char = nil
  local i = 1

  while i <= #str do
    local char = str:sub(i, i)

    if not in_quotes then
      if char == '"' or char == "'" then
        in_quotes = true
        quote_char = char
      elseif char:match("%s") then
        if current ~= "" then
          table.insert(args, current)
          current = ""
        end
      else
        current = current .. char
      end
    else
      if char == quote_char then
        in_quotes = false
        quote_char = nil
      else
        current = current .. char
      end
    end

    i = i + 1
  end

  if current ~= "" then
    table.insert(args, current)
  end

  return args
end

vim.api.nvim_create_user_command('Gr', function(opts)
  if opts.args == "" then
    snacks.picker.grep()
  else
    local args = parse_args(opts.args)
    local search = nil
    local dirs = nil
    local glob = nil

    -- Обрабатываем аргументы
    local i = 1
    while i <= #args do
      local arg = args[i]

      if i == 1 then
        -- Первый аргумент - строка поиска
        search = arg
      elseif arg == "-G" or arg == "--glob" then
        -- Флаг паттерна файлов
        i = i + 1
        if i <= #args then
          glob = args[i]
        end
      elseif i == 2 then
        -- Второй аргумент - либо директория, либо паттерн (если начинается с *)
        if arg:match("^%*") or arg:match("%.") then
          glob = arg
        else
          dirs = { arg }
        end
      elseif i == 3 then
        -- Третий аргумент - паттерн файлов
        glob = arg
      end

      i = i + 1
    end

    local grep_opts = { focus = "list" }
    if search then
      grep_opts.search = search
    end
    if dirs then
      grep_opts.dirs = dirs
    end
    if glob then
      grep_opts.glob = glob
    end

    snacks.picker.grep(grep_opts)
  end
end, { nargs = "*", desc = 'Search using Snacks.picker.grep()' })
