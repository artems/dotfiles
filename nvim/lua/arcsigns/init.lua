--- arcsigns — teaches gitsigns.nvim to speak arc (Arcadia's VCS).
---
--- gitsigns keeps all VCS specifics behind two objects, Gitsigns.GitObj and
--- Gitsigns.Repo, both handed out by the gitsigns.git module. We preload a
--- replacement for that module which routes arc working copies to our own
--- implementation and everything else to the real one, so gitsigns itself stays
--- unforked.
---
--- setup() must run before gitsigns' own setup(): lazy.nvim sources
--- gitsigns.nvim/plugin/gitsigns.lua (which calls require('gitsigns').setup())
--- in loader.lua:359, before it runs spec.config in loader.lua:362. Hence the
--- call lives in init.lua ahead of require('lazy').setup().

local M = {}

--- @param opts? table See ArcSigns.Config
function M.setup(opts)
  require('arcsigns.config').set(opts)

  package.preload['gitsigns.git'] = function()
    return require('arcsigns.router')
  end

  if not require('arcsigns.config').get().current_line_blame then
    package.preload['gitsigns.current_line_blame'] = function()
      return require('arcsigns.clb').patched()
    end
  end

  vim.api.nvim_create_user_command('ArcsignsReload', function()
    require('arcsigns.detect').flush()
    require('arcsigns.blame').reset_slow()
    vim.notify('arcsigns: caches cleared', vim.log.levels.INFO)
  end, { desc = 'Clear arcsigns detection and slow-blame caches' })
end

return M
