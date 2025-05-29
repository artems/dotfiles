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

vim.keymap.del("n", "grn")
vim.keymap.del("n", "gra")
vim.keymap.del("n", "grr")
vim.keymap.del("n", "gri")

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.HINT] = "󰌶",
    },
  },
  float = { border = "solid" }
})

vim.api.nvim_create_augroup("vimrc_lspconfig_attach", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = "vimrc_lspconfig_attach",
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    local lazy_telescope = function(func, opts)
      return function(...)
        local telescope = require("telescope.builtin")
        opts = opts or require('telescope.themes').get_dropdown()

        local args = {...}
        if args[1] and type(args[1]) == "table" then
          local merged_opts = vim.tbl_deep_extend("force", opts, args[1])
          args[1] = merged_opts
        else
          table.insert(args, 1, opts)
        end

        return telescope[func](unpack(args))
      end
    end

    map('K', function()
      vim.lsp.buf.hover({ border = "solid" })
    end, "Show information about the symobl under the cursor")

    -- Jump to the definition of the word under cursor.
    map("gd", lazy_telescope("lsp_definitions"), "Goto definition")

    -- Find references for the word under your cursor.
    map("gr", lazy_telescope("lsp_references"), "Goto references")

    -- Jump to the implementation of the word under cursor.
    map("gI", lazy_telescope("lsp_implementations"), "Goto implementation")

    -- Jump to the type definition of the word under cursor.
    map("gD", lazy_telescope("lsp_type_definitions"), "Goto type definition")

    -- Fuzzy find all the symbols in your current document.
    map("<leader>ds", lazy_telescope("lsp_document_symbols"), "Search document symbols")

    -- Fuzzy find all the symbols in your current workspace.
    map("<leader>ws", lazy_telescope("lsp_dynamic_workspace_symbols"), "Search workspace symbols")

    -- Rename the variable under cursor.
    map("<leader>cr", vim.lsp.buf.rename, "Code action: Rename")

    -- Execute a code action
    map("<leader>ca", vim.lsp.buf.code_action, "Code action: Choose", { "n", "x" })

    -- This function resolves a difference between neovim version 0.11 and version 0.10
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has("nvim-0.11") == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    local documentHighlightAvailable = client and client_supports_method(
      client,
      vim.lsp.protocol.Methods.textDocument_documentHighlight,
      event.buf
    )
    if documentHighlightAvailable then
      local highlight_augroup = vim.api.nvim_create_augroup("vimrc_lsp_highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_augroup,
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight_augroup,
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    local inlayHintAbailable = client and client_supports_method(
      client,
      vim.lsp.protocol.Methods.textDocument_inlayHint,
      event.buf
    )
    if inlayHintAbailable then
      map("<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
      end, "Toggle inlay hints")
    end
  end,
})

vim.api.nvim_create_augroup("vimrc_lspconfig_detach", { clear = true })
vim.api.nvim_create_autocmd("LspDetach", {
  group = "vimrc_lspconfig_detach",
  callback = function(event)
    vim.api.nvim_clear_autocmds({ group = "vimrc_lsp_highlight", buffer = event.buf })
    vim.lsp.buf.clear_references()
  end,
})
