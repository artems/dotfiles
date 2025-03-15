local lspconfig = require('lspconfig')
local capabilities = require('blink.cmp').get_lsp_capabilities()

lspconfig.lua_ls.setup({
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath('config') and (
        vim.loop.fs_stat(path .. '/.luarc.json') or
        vim.loop.fs_stat(path .. '/.luarc.jsonc')
      ) then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend(
      'force',
      client.config.settings.Lua,
      {
        runtime = { version = 'LuaJIT' },
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
lspconfig.yamlls.setup({ capabilities = capabilities });
lspconfig.pyright.setup({ capabilities = capabilities })
