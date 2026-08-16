--- Stands in for gitsigns.git (installed via package.preload).
---
--- gitsigns only ever uses this module as a namespace — `git.Obj.new`
--- (attach.lua:317,321), `git.Repo.get` (actions/qflist.lua:70) and
--- `git.Repo.get_info` (gitsigns.lua:44,79) — so flat dispatch tables suffice.
--- Anything that is not an arc path is delegated to the real gitsigns.git.

local compat = require('arcsigns.compat')
local detect = require('arcsigns.detect')

local M = {}

--- Pick a backend from whichever identifiers gitsigns happened to pass.
--- @param file? string
--- @param gitdir? string
--- @param toplevel? string
--- @return 'arc'|'git'
local function backend(file, gitdir, toplevel)
  if gitdir then
    -- gitsigns:// buffers arrive with a gitdir only (file is a relpath), so
    -- this branch has to work without touching the filesystem.
    if gitdir:sub(-5) == '/.arc' then
      return 'arc'
    elseif gitdir:sub(-5) == '/.git' or gitdir == '.git' then
      return 'git'
    end
  end

  if toplevel and detect.workspace(toplevel) then
    return 'arc'
  end

  if file and file:sub(1, 1) == '/' and detect.workspace(file) then
    return 'arc'
  end

  return 'git'
end

M.backend = backend

M.Obj = {
  --- @async
  --- @param file string
  --- @param revision string?
  --- @param encoding string
  --- @param gitdir string?
  --- @param toplevel string?
  --- @return table?
  new = function(file, revision, encoding, gitdir, toplevel)
    if backend(file, gitdir, toplevel) == 'arc' then
      return require('arcsigns.obj').new(file, revision, encoding, gitdir, toplevel)
    end
    return compat.real_git().Obj.new(file, revision, encoding, gitdir, toplevel)
  end,
}

M.Repo = {
  --- @async
  get = function(cwd, gitdir, toplevel)
    if backend(nil, gitdir, toplevel or cwd) == 'arc' then
      return require('arcsigns.repo').get(cwd, gitdir, toplevel)
    end
    return compat.real_git().Repo.get(cwd, gitdir, toplevel)
  end,

  --- @async
  get_info = function(dir, gitdir, worktree) --- @diagnostic disable-line: unused-local
    if backend(nil, gitdir, worktree or dir) == 'arc' then
      return require('arcsigns.repo').get_info(dir, gitdir, worktree)
    end
    return compat.real_git().Repo.get_info(dir, gitdir, worktree)
  end,

  --- Pure predicate, identical for both backends: a revision is "from tree"
  --- unless it names an index stage (':0', ':1', ...).
  --- @param revision? string
  --- @return boolean
  from_tree = function(revision)
    return revision ~= nil and not vim.startswith(revision, ':')
  end,
}

return M
