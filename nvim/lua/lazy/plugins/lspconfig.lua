local lspconfig = require('lspconfig')

lspconfig.hls.setup({})

lspconfig.lua_ls.setup({
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath('config') and (
        vim.loop.fs_stat(path..'/.luarc.json') or
        vim.loop.fs_stat(path..'/.luarc.jsonc')
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

lspconfig.html.setup({})
lspconfig.cssls.setup({})
lspconfig.jsonls.setup({})

lspconfig.ts_ls.setup({ init_options = { maxTsServerMemory = 8192 } })
lspconfig.eslint.setup({})

lspconfig.pyright.setup({})
