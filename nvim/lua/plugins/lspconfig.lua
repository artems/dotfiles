vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath("config") and (
        vim.loop.fs_stat(path .. "/.luarc.json") or
        vim.loop.fs_stat(path .. "/.luarc.jsonc")
      ) then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend(
      "force",
      client.config.settings.Lua,
      {
        runtime = {
          version = "LuaJIT",
          path = {
            'lua/?.lua',
            'lua/?/init.lua',
          },
        },
        -- Make the server aware of Neovim runtime files
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            "${3rd}/luv/library",
            "${3rd}/busted/library",
          },
          checkThirdParty = false,
        }
      }
    )
  end,
  settings = { Lua = {} },
})

vim.lsp.config('ts_ls', {
  init_options = { maxTsServerMemory = 8192 },
})

vim.lsp.enable('html');
vim.lsp.enable('cssls');
vim.lsp.enable('jsonls');

vim.lsp.enable('ts_ls');
vim.lsp.enable('eslint');
vim.lsp.enable('stylelint_lsp');

vim.lsp.enable('hls');
vim.lsp.enable('lua_ls');
vim.lsp.enable('clangd');
vim.lsp.enable('yamlls');
vim.lsp.enable('pyright');

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.HINT] = "󰌶",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.ERROR] = "󰅚",
    },
  },
  float = { border = "rounded" },
  underline = { severity = vim.diagnostic.severity.ERROR },
})

vim.api.nvim_create_augroup("vimrc_lspconfig_attach", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = "vimrc_lspconfig_attach",
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    local lazy_picker = function(func)
      return function(...)
        local picker = require("snacks.picker")
        local opts = { focus = "list" }

        local args = {...}
        if args[1] and type(args[1]) == "table" then
          local merged_opts = vim.tbl_deep_extend("force", opts, args[1])
          args[1] = merged_opts
        else
          table.insert(args, 1, opts)
        end

        return picker[func](unpack(args))
      end
    end

    map('K', function()
      vim.lsp.buf.hover({ border = "rounded" })
    end, "Show information about the symobl under the cursor")

    -- Jump to the definition of the word under cursor.
    map("gd", lazy_picker("lsp_definitions"), "Goto definition")

    -- Find references for the word under your cursor.
    map("grr", lazy_picker("lsp_references"), "Goto references")

    -- Jump to the implementation of the word under cursor.
    map("gri", lazy_picker("lsp_implementations"), "Goto implementation")

    -- Jump to the type definition of the word under cursor.
    map("grt", lazy_picker("lsp_type_definitions"), "Goto type definition")

    -- Fuzzy find all the symbols in your current document.
    map("gO", lazy_picker("lsp_symbols"), "Search document symbols")

    -- Fuzzy find all the symbols in your current workspace.
    map("gW", lazy_picker("lsp_workspace_symbols"), "Search workspace symbols")

    -- Rename the variable under cursor.
    map("grn", vim.lsp.buf.rename, "Code action: Rename")

    -- Execute a code action
    map("gra", vim.lsp.buf.code_action, "Code action: Choose", { "n", "x" })
  end,
})
