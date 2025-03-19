local lspconfig = require("lspconfig")
local capabilities = require("blink.cmp").get_lsp_capabilities({}, true)

lspconfig.lua_ls.setup({
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
        runtime = { version = "LuaJIT" },
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

lspconfig.html.setup({ capabilities = capabilities })
lspconfig.cssls.setup({ capabilities = capabilities })
lspconfig.jsonls.setup({ capabilities = capabilities })

lspconfig.ts_ls.setup({
  capabilities = capabilities,
  init_options = { maxTsServerMemory = 8192 },
})
lspconfig.eslint.setup({ capabilities = capabilities })

lspconfig.hls.setup({ capabilities = capabilities })
lspconfig.clangd.setup({ capabilities = capabilities })
lspconfig.yamlls.setup({ capabilities = capabilities })
lspconfig.pyright.setup({ capabilities = capabilities })

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.HINT] = "󰌶",
    },
  },
})

vim.api.nvim_create_augroup("vimrc_lspconfig_attach", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = "vimrc_lspconfig_attach",
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "lsp: " .. desc })
    end

    local lazy_telescope = function(func)
      return function(...)
        local telescope = require("telescope.builtin")
        return telescope[func](...)
      end
    end

    -- Jump to the definition of the word under cursor.
    map("gd", vim.lsp.buf.definition, "[g]oto [d]efinition")

    -- Jump to the implementation of the word under cursor.
    map("gI", vim.lsp.buf.implementation, "[g]oto [I]mplementation")

    -- Jump to the type definition of the word under cursor.
    map("gD", vim.lsp.buf.type_definition, "[g]oto type [D]efinition")

    -- Find references for the word under your cursor.
    map("gR", vim.lsp.buf.references, "[g]oto [R]eferences")

    -- Fuzzy find all the symbols in your current document.
    map("<leader>ds", lazy_telescope("lsp_document_symbols"), "[d]ocument [s]ymbols")

    -- Fuzzy find all the symbols in your current workspace.
    map("<leader>ws", lazy_telescope("lsp_dynamic_workspace_symbols"), "[w]orkspace [s]ymbols")

    -- Rename the variable under cursor.
    map("<leader>cr", vim.lsp.buf.rename, "[c]ode action: [r]ename")

    -- Execute a code action
    map("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction", { "n", "x" })

    -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has "nvim-0.11" == 1 then
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
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, "[t]oggle inlay [h]ints")
    end
  end,
})

vim.api.nvim_create_augroup("vimrc_lspconfig_detach", { clear = true })
vim.api.nvim_create_autocmd("LspDetach", {
  group = "vimrc_lspconfig_detach",
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds({ group = "vimrc_lsp_highlight", buffer = event.buf })
  end,
})
