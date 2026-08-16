--- ArcSigns.Obj — the arc-backed stand-in for Gitsigns.GitObj.
---
--- Mirrors gitsigns/git.lua; the field set and the return conventions
--- (notably `{''}` for untracked files and `{}` when there is no relpath) are
--- load-bearing for gitsigns' manager and actions.

local log = require('gitsigns.debug.log')
local util = require('gitsigns.util')

local Repo = require('arcsigns.repo')

--- @class ArcSigns.Obj
--- @field file string
--- @field encoding string
--- @field mode_bits? string
--- @field revision? string Nil means the index
--- @field object_name? string Nil means untracked
--- @field relpath? string
--- @field orig_relpath? string Set while a move is being tracked
--- @field repo ArcSigns.Repo
--- @field has_conflicts? boolean
--- @field i_crlf? boolean
--- @field w_crlf? boolean
--- @field private _closed boolean
--- @field private _gc userdata
local Obj = {}
Obj.__index = Obj

local M = { mt = Obj }

--- @async
--- @param revision? string
--- @return string? err
function Obj:change_revision(revision)
  self.revision = util.norm_base(revision)
  return self:refresh()
end

--- @async
--- @generic R
--- @param fn async fun(): R...
--- @return R...
function Obj:lock(fn)
  return self.repo:lock(fn)
end

--- @async
--- @return string? err
function Obj:refresh()
  local info, err = self.repo:file_info(self.file, self.revision)

  if err then
    log.eprint(err)
  end

  if not info then
    return err
  end

  self.relpath = info.relpath
  self.object_name = info.object_name
  self.mode_bits = info.mode_bits
  self.has_conflicts = info.has_conflicts
  self.i_crlf = info.i_crlf
  self.w_crlf = info.w_crlf
end

function Obj:close()
  if self._closed then
    return
  end

  self._closed = true
  self.repo:unref()
  self.repo = nil
end

--- @return boolean
function Obj:closed()
  return self._closed
end

--- @return boolean
function Obj:from_tree()
  return require('arcsigns.router').Repo.from_tree(self.revision)
end

--- @async
--- @param revision? string
--- @param relpath? string
--- @return string[] stdout, string? stderr
function Obj:get_show_text(revision, relpath)
  relpath = relpath or self.relpath

  if revision and not relpath then
    log.dprint('arcsigns: no relpath')
    return {}
  end

  if not revision and not self.object_name then
    log.dprint('arcsigns: no revision or object_name')
    return { '' }
  end

  if revision then
    --- @cast relpath -?
    return self.repo:get_show_text_at_revision(revision, relpath, self.encoding)
  end

  -- ':<path>' rather than object_name: ours is a content hash, not something
  -- `arc show` accepts, and reading the path always yields the current index.
  return self.repo:get_show_text(':' .. assert(relpath), self.encoding)
end

--- @async
--- @param contents? string[]
--- @param lnum? integer|[integer, integer]
--- @param revision? string
--- @param opts? Gitsigns.BlameOpts
--- @return table<integer, Gitsigns.BlameInfo?>
--- @return table<string, Gitsigns.CommitInfo?>
function Obj:run_blame(contents, lnum, revision, opts)
  return require('arcsigns.blame').run_blame(self, contents, lnum, revision, opts)
end

--- @async
--- @param hunks Gitsigns.Hunk.Hunk[]
--- @param invert? boolean
--- @return string? err
function Obj:stage_hunks(hunks, invert)
  return require('arcsigns.stage').stage_hunks(self, hunks, invert)
end

--- @async
--- Stage `lines` as the entire contents of the file.
--- @param lines string[]
function Obj:stage_lines(lines)
  return require('arcsigns.stage').stage_lines(self, lines)
end

--- @async
function Obj:unstage_file()
  return require('arcsigns.stage').unstage_file(self)
end

--- @async
--- @param file string Absolute path, or relative to toplevel
--- @param revision? string
--- @param encoding string
--- @param gitdir? string
--- @param toplevel? string
--- @return ArcSigns.Obj?
function M.new(file, revision, encoding, gitdir, toplevel)
  local cwd = toplevel
  if not cwd and util.Path.is_abs(file) then
    cwd = vim.fn.fnamemodify(file, ':h')
  end

  local repo, err = Repo.get(cwd, gitdir, toplevel)
  if not repo then
    log.dprintf('arcsigns: not in an arc repo: %s', err or '?')
    return
  end

  if vim.startswith(vim.fs.normalize(file), repo.gitdir .. '/') then
    log.dprint('arcsigns: in arcdir')
    repo:unref()
    return
  end

  revision = util.norm_base(revision)

  local info, err2 = repo:file_info(file, revision)
  if err2 then
    log.dprint(err2)
  end

  if not info then
    repo:unref()
    return
  end

  if info.relpath then
    file = util.Path.join(repo.toplevel, info.relpath)
  end

  local self = setmetatable({}, Obj)
  self.repo = repo
  self._closed = false
  self._gc = util.gc_proxy(function()
    self:close()
  end)
  self.file = file
  self.revision = revision
  self.encoding = encoding

  self.relpath = info.relpath
  self.object_name = info.object_name
  self.mode_bits = info.mode_bits
  self.has_conflicts = info.has_conflicts
  self.i_crlf = info.i_crlf
  self.w_crlf = info.w_crlf

  return self
end

return M
