--- Suppressing gitsigns' current-line blame in arc buffers.
---
--- `arc blame` has no --contents and costs 25-40s on files with a large history
--- (build/ymake_conf.py), so running it on every cursor move is not viable.
--- Explicit blame (<leader>hb / :Gitsigns blame_line) still works.
---
--- Everything routes through M.update — attach.lua:434, M.refresh at
--- current_line_blame.lua:246, and the autocmd at :270 all index M at call
--- time — so patching that one field is enough.

local compat = require('arcsigns.compat')

local M = {}

--- @param bufnr integer
--- @return boolean
local function is_arc_buffer(bufnr)
  local ok, cache = pcall(require, 'gitsigns.cache')
  if not ok then
    return false
  end

  local bcache = cache.cache[bufnr]
  local obj = bcache and bcache.git_obj
  if not obj then
    return false
  end

  -- By metatable rather than by path: this also covers gitsigns:// buffers and
  -- costs no filesystem access.
  return getmetatable(obj) == require('arcsigns.obj').mt
end

--- @return table The real gitsigns.current_line_blame, with update() patched
function M.patched()
  local clb = compat.real_module('gitsigns.current_line_blame')
  local orig = clb.update

  clb.update = function(bufnr, ...)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if is_arc_buffer(bufnr) then
      vim.notify_once(
        'arcsigns: current-line blame is off in arc repos (too slow); use :Gitsigns blame_line',
        vim.log.levels.INFO
      )
      return
    end
    return orig(bufnr, ...)
  end

  return clb
end

return M
