--- arcsnacks — teaches snacks.nvim to speak arc (Arcadia's VCS).
---
--- Companion to arcsigns, which does the same for gitsigns. Both lean on
--- arcsigns.detect to decide, per path, whether something is an arc working
--- copy; anything it does not claim keeps using git, so a git repo and an arc
--- working copy stay usable in the same session.
---
--- Unlike arcsigns this patches modules in place instead of preloading
--- replacements: snacks requires its submodules lazily and caches them, so
--- swapping a function on the loaded module sticks, and upstream code that
--- calls it (explorer actions, picker sources) picks the new one up.
---
--- setup() must run after snacks itself is loaded — see plugins/snacks-init.lua.

local M = {}

--- @param opts? table Reserved for future options
function M.setup(opts) --- @diagnostic disable-line: unused-local
  require('arcsnacks.explorer').setup()
  require('arcsnacks.watch').setup()
  require('arcsnacks.picker').setup()
end

return M
