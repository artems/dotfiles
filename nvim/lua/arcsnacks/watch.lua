--- Keeping the explorer's file watcher useful in an arc working copy.
---
--- Upstream watches `<root>/.git` and refreshes when `index` changes. In arc
--- there is no such directory to watch: `<toplevel>/.arc` is a FUSE-backed
--- inode that does not deliver events, and the real metadata lives in the
--- store (~/.arc/stores/<mangled>/.arc). arcsigns.watcher already knows this;
--- we only need the same insight, not its gitsigns-flavoured machinery.
---
--- This is a fork of snacks.explorer.watch.watch() rather than a wrapper: the
--- original ends by stopping every watch it did not register this round, so an
--- extra handle added from the outside would be torn down immediately. Keeping
--- ours in the same M._watches table lets that bookkeeping keep working.

local route = require('arcsnacks.route')

local M = {}

--- Files in the arc store whose changes actually mean something. The daemon
--- writes logs/, traces/, arc.pid and port constantly; those must not trigger
--- a refresh.
local INTERESTING = {
  HEAD = true,
  TREE = true,
  stage = true,
  ORIG_HEAD = true,
}

--- @type boolean
local patched = false

function M.setup()
  if patched then
    return
  end
  patched = true

  local Watch = require('snacks.explorer.watch')
  local Git = require('snacks.explorer.git')
  local Tree = require('snacks.explorer.tree')

  function Watch.watch()
    local used = {} --- @type table<string, boolean>

    local cwds = {} --- @type table<string, boolean>
    for _, picker in ipairs(Snacks.picker.get({ source = 'explorer', tab = false })) do
      cwds[picker:cwd()] = true
    end

    for cwd in pairs(cwds) do
      local mount = route.mount(cwd)

      if mount then
        local base = mount.store or mount.arcdir
        if vim.fn.isdirectory(base) == 1 then
          used[base] = true
          Watch.start(base, function(file)
            if INTERESTING[vim.fs.basename(file)] then
              Git.refresh(mount.toplevel)
              Watch.refresh()
            end
          end)
        end
      else
        local root = Snacks.git.get_root(cwd)
        if root then
          used[root .. '/.git'] = true
          Watch.start(root .. '/.git', function(file)
            if vim.fs.basename(file) == 'index' then
              Git.refresh(root)
              Watch.refresh()
            end
          end)
        end
      end

      -- Watch open directories (unchanged from upstream)
      Tree:walk(Tree:find(cwd), function(node)
        if node.dir and node.open then
          used[node.path] = true
          Watch.start(node.path)
        end
      end)
    end

    for path in pairs(Watch._watches) do
      if not used[path] then
        Watch.stop(path)
      end
    end
  end
end

return M
