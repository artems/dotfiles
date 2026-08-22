--- Teaching Snacks.explorer to show arc status in the tree.
---
--- All of the explorer's VCS knowledge lives in two functions of
--- snacks.explorer.git: update() spawns `git status` and is_dirty() decides
--- whether the cached result is stale. Everything downstream — spreading the
--- codes over the tree, merging them into parent directories, and the ]g / [g
--- jumps in explorer/actions.lua — works off node.status and does not care
--- where the codes came from.
---
--- So we replace exactly those two functions and keep the originals for
--- non-arc paths. The TTL/tick bookkeeping is mirrored from upstream (and
--- shares its M.state table) so that a git repo and an arc working copy can be
--- open side by side without either invalidating the other's cache.

local route = require('arcsnacks.route')

local M = {}

local CACHE_TTL = 15 * 60 -- keep in step with snacks/explorer/git.lua

--- @type boolean
local patched = false

function M.setup()
  if patched then
    return
  end
  patched = true

  local Git = require('snacks.explorer.git')
  local orig_update = Git.update
  local orig_is_dirty = Git.is_dirty

  --- @param cwd string
  function Git.is_dirty(cwd)
    local root = route.root(cwd)
    if not root then
      return orig_is_dirty(cwd)
    end
    return Git.state[root] == nil or Git.state[root].last == 0
  end

  --- @param cwd string
  --- @param opts? {on_update?: fun(), ttl?: number, force?: boolean, untracked?: boolean}
  function Git.update(cwd, opts)
    local root = route.root(cwd)
    if not root then
      return orig_update(cwd, opts)
    end

    opts = opts or {}
    local ttl = opts.force and 0 or (opts.ttl or CACHE_TTL)

    local now = os.time()
    Git.state[root] = Git.state[root] or { tick = 0, last = 0 }
    local state = Git.state[root]
    if now - state.last < ttl then
      return
    end
    state.last = now
    state.tick = state.tick + 1
    local tick = state.tick

    local untracked = opts.untracked ~= false and 'normal' or 'no'
    require('arcsnacks.status').fetch(root, { untracked = untracked }, function(entries)
      vim.schedule(function()
        -- A newer update was started while we were out; its answer wins.
        if not Git.state[root] or Git.state[root].tick ~= tick then
          return
        end

        -- Upstream marks .git as ignored so it stays out of the tree; .arc is
        -- the same kind of noise.
        if vim.fn.isdirectory(cwd .. '/.arc') == 1 then
          table.insert(entries, 1, { status = '!!', file = cwd .. '/.arc' })
        end

        if Git._update(cwd, entries) and opts.on_update then
          opts.on_update()
        end
      end)
    end)
  end
end

return M
