--- ArcSigns.Repo — the arc-backed stand-in for Gitsigns.Repo.
---
--- Structure follows gitsigns/git/repo.lua closely (ref counting, the creation
--- semaphore, a watcher owning HEAD state) so the two behave alike from
--- gitsigns' point of view.

local async = require('gitsigns.async')
local bit = require('bit')
local log = require('gitsigns.debug.log')

local uv = vim.uv or vim.loop ---@diagnostic disable-line: deprecated

local cmd = require('arcsigns.cmd')
local detect = require('arcsigns.detect')
local head_reader = require('arcsigns.head')

--- @class ArcSigns.Repo
--- @field gitdir string `<toplevel>/.arc`
--- @field toplevel string
--- @field abbrev_head string
--- @field detached boolean
--- @field head_oid? string
--- @field head_ref? string
--- @field username? string
--- @field mount ArcSigns.Mount
--- @field private _lock Gitsigns.async.Semaphore
--- @field private _refs integer
--- @field private _watcher? ArcSigns.Watcher
--- @field private _blob_cache? { object: string, lines: string[] }
local M = {}

--- @type table<string, ArcSigns.Repo>
local repo_cache = setmetatable({}, { __mode = 'v' })

--- Logins are per user, not per repository.
--- @type string?
local username_cache

--- @class ArcSigns.RepoInfo
--- @field gitdir string
--- @field toplevel string
--- @field abbrev_head string
--- @field detached boolean
--- @field head_oid? string
--- @field head_ref? string
--- @field mount ArcSigns.Mount

--- Repository metadata. Costs no subprocess: the mount table plus a couple of
--- small reads out of .arc.
--- @param dir? string
--- @param gitdir? string
--- @param toplevel? string
--- @return ArcSigns.RepoInfo?, string? err
function M.get_info(dir, gitdir, toplevel)
  local mount --- @type ArcSigns.Mount?

  if gitdir then
    mount = detect.by_arcdir(gitdir)
  end
  if not mount and toplevel then
    mount = detect.workspace(toplevel)
  end
  if not mount and dir then
    mount = detect.workspace(dir)
  end

  if not mount then
    return nil, 'not in an arc working copy'
  end

  local head = head_reader.read(mount)

  return {
    gitdir = mount.arcdir,
    toplevel = mount.toplevel,
    abbrev_head = head.abbrev_head,
    detached = head.detached,
    head_oid = head.head_oid,
    head_ref = head.head_ref,
    mount = mount,
  }
end

--- @async
--- @param info ArcSigns.RepoInfo
--- @return ArcSigns.Repo
function M._new(info)
  local self = setmetatable(info, { __index = M }) --[[@as ArcSigns.Repo]]
  self._lock = async.semaphore(1)
  self._refs = 0

  if username_cache == nil then
    local i = cmd.json({ 'info' }, { cwd = self.toplevel })
    username_cache = i and i.user_login or false
  end
  self.username = username_cache or nil

  local config = require('gitsigns.config').config
  if config.watch_gitdir.enable then
    self._watcher = require('arcsigns.watcher').new(self.mount)
    self._watcher:set_head_ref(self.head_ref)

    -- Registered first, so HEAD state is refreshed before the per-buffer
    -- callbacks that read it (attach.lua:218,235).
    self._watcher:on_update(function()
      local head = head_reader.read(self.mount)

      self.head_oid = head.head_oid
      if self.abbrev_head ~= head.abbrev_head then
        self.abbrev_head = head.abbrev_head
        log.dprintf('arcsigns: HEAD changed, abbrev_head is now %s', self.abbrev_head)
      end

      if self.head_ref ~= head.head_ref then
        self.head_ref = head.head_ref
        self._watcher:set_head_ref(head.head_ref)
      end
    end)
  end

  return self
end

local sem = async.semaphore(1)

--- @async
--- @param cwd? string
--- @param gitdir? string
--- @param toplevel? string
--- @return ArcSigns.Repo?, string? err
function M.get(cwd, gitdir, toplevel)
  --- @return ArcSigns.Repo?, string?
  return sem:with(function()
    local info, err = M.get_info(cwd, gitdir, toplevel)
    if not info then
      return nil, err
    end

    local repo = repo_cache[info.gitdir]
    if repo then
      repo.abbrev_head = info.abbrev_head
      repo.detached = info.detached
      repo.head_oid = info.head_oid
    else
      repo = M._new(info)
      repo_cache[info.gitdir] = repo
    end

    repo:ref()
    return repo
  end)
end

function M:_close()
  repo_cache[self.gitdir] = nil
  if self._watcher then
    self._watcher:close()
    self._watcher = nil
  end
end

function M:ref()
  self._refs = self._refs + 1
  return self
end

function M:unref()
  if self._refs == 0 then
    return
  end

  self._refs = self._refs - 1
  if self._refs == 0 then
    self:_close()
  end
end

function M:has_watcher()
  return self._watcher ~= nil
end

--- @param callback fun()
--- @return fun() deregister
function M:on_update(callback)
  assert(self._watcher, 'arcsigns: watcher not initialized')
  return self._watcher:on_update(callback)
end

--- @async
--- @generic R
--- @param fn async fun(): R...
--- @return R...
function M:lock(fn)
  return self._lock:with(fn)
end

--- Run an arc command in this working copy.
---
--- arc resolves paths relative to the process CWD, so every call must be
--- anchored at toplevel; `arc show :<path>` additionally insists on a
--- toplevel-relative path.
--- @async
--- @param args string[]
--- @param spec? ArcSigns.JobSpec
--- @return string[] stdout, string? stderr, integer code
function M:arc(args, spec)
  spec = vim.tbl_extend('keep', spec or {}, { cwd = self.toplevel })
  return cmd.run(args, spec)
end

--- @async
--- @param args string[]
--- @param spec? ArcSigns.JobSpec
--- @return any?, string? err
function M:arc_json(args, spec)
  spec = vim.tbl_extend('keep', spec or {}, { cwd = self.toplevel })
  return cmd.json(args, spec)
end

--- Path relative to toplevel, or nil if the file lies outside the working copy.
--- @param file string
--- @return string?
function M:relpath(file)
  if file == '' then
    return nil
  end

  if not vim.startswith(file, '/') then
    return file
  end

  local path = vim.fs.normalize(file)
  if path == self.toplevel then
    return nil
  elseif vim.startswith(path, self.toplevel .. '/') then
    return path:sub(#self.toplevel + 2)
  end
end

--- @param encoding string
--- @return boolean
local function iconv_supported(encoding)
  return not vim.startswith(encoding, 'utf-16') and not vim.startswith(encoding, 'utf-32')
end

--- @async
--- Contents of an object. `object` accepts every form gitsigns uses: a bare
--- blob hash, ':<path>', ':0:<path>', 'HEAD:<path>', '<sha>:<path>'.
--- @param object string
--- @param encoding? string
--- @return string[] stdout, string? stderr
function M:get_show_text(object, encoding)
  local stdout, stderr

  local cached = self._blob_cache
  if cached and cached.object == object then
    -- file_info already fetched this blob moments ago; spend one subprocess,
    -- not two, on the common attach path.
    self._blob_cache = nil
    stdout = cached.lines
  else
    stdout, stderr = self:arc({ 'show', object }, { text = false, ignore_error = true })
  end

  if encoding and encoding ~= 'utf-8' and iconv_supported(encoding) then
    for i, l in ipairs(stdout) do
      stdout[i] = vim.iconv(l, encoding, 'utf-8')
    end
  end

  return stdout, stderr
end

--- @async
--- @param revision string
--- @param relpath string
--- @param encoding? string
--- @return string[] stdout, string? stderr
function M:get_show_text_at_revision(revision, relpath, encoding)
  -- No rename resolution: arc has no rename-aware equivalent we can rely on
  -- (see diff_rename_status below).
  return self:get_show_text(revision .. ':' .. relpath, encoding)
end

--- @class ArcSigns.FileInfo
--- @field relpath? string
--- @field mode_bits? string
--- @field object_name? string
--- @field has_conflicts? boolean
--- @field i_crlf? boolean
--- @field w_crlf? boolean

--- File mode, derived from the working tree. arc exposes modes only via
--- `ls-tree`, which would cost another subprocess; gitsigns only ever compares
--- this value with its previous self.
--- @param file string
--- @return string?
local function mode_bits(file)
  local stat = uv.fs_stat(file)
  if not stat then
    return nil
  end
  return bit.band(stat.mode, 73) ~= 0 and '100755' or '100644'
end

--- @async
--- Index/tree metadata for a file. Shape matches Gitsigns.Repo.LsFiles.Result.
---
--- `object_name` is a content hash rather than an arc object id: `arc ls-tree :`
--- reports the HEAD tree and ignores the index entirely, so it cannot tell us
--- whether the staged blob changed. gitsigns only ever compares object_name
--- with its previous value (attach.lua:222-245) and passes it back to
--- get_show_text, so any stable content identifier will do.
--- @param file string
--- @param revision? string
--- @return ArcSigns.FileInfo?, string? err
function M:file_info(file, revision)
  local relpath = self:relpath(file)
  if not relpath then
    return nil, 'outside the arc working copy'
  end

  local from_tree = require('arcsigns.router').Repo.from_tree(revision)
  local object = (from_tree and assert(revision) or '') .. ':' .. relpath

  local lines, _, code = self:arc({ 'show', object }, { text = false, ignore_error = true })

  if code == 0 then
    local content = table.concat(lines, '\n')
    -- Remember the blob so the get_show_text() that follows attach does not
    -- have to fetch it a second time.
    self._blob_cache = { object = object, lines = lines }
    return {
      relpath = relpath,
      mode_bits = mode_bits(file),
      object_name = vim.fn.sha256(content),
    }
  end

  if from_tree then
    -- Not in that revision, and there is no index to fall back on.
    return {}
  end

  -- Absent from the index: untracked, ignored, or gone.
  local others = self:arc({ 'ls-files', '-o', relpath }, { ignore_error = true })
  if others[1] then
    return { relpath = relpath }
  end

  return {}
end

--- arc has no gitattributes. 'unspecified' is the value that makes gitsigns
--- neither skip the buffer (attach.lua:364 only rejects 'unset') nor drop the
--- file from the quickfix list (qflist.lua:85).
--- @param _attr string
--- @param files string[]
--- @return table<string, string>
function M:check_attr(_attr, files)
  local res = {} --- @type table<string, string>
  for _, f in ipairs(files) do
    res[f] = 'unspecified'
  end
  return res
end

--- Rename tracking is not implemented: arc's --resolve-moves is experimental.
--- Returning {} makes attach.lua's handle_moved bail out quietly.
--- @return table<string, string>
function M:diff_rename_status()
  return {}
end

--- @async
--- @param base? string
--- @param include_untracked? boolean
--- @return {path: string, oldpath?: string, deleted?: boolean}[]
function M:files_changed(base, include_untracked)
  local res = {} --- @type {path: string, oldpath?: string, deleted?: boolean}[]

  if base and not vim.startswith(base, ':') then
    local out = self:arc({ 'diff', '--name-status', base }, { ignore_error = true })
    for _, line in ipairs(out) do
      local status, rest = line:match('^(%a)%d*%s+(.*)$')
      if status == 'R' then
        local oldpath, path = rest:match('^(%S+)%s+(%S+)$')
        res[#res + 1] = { path = path or rest, oldpath = oldpath }
      elseif status == 'D' then
        res[#res + 1] = { path = rest, deleted = true }
      elseif status then
        res[#res + 1] = { path = rest }
      end
    end
    return res
  end

  for _, path in ipairs(self:arc({ 'ls-files', '-m' }, { ignore_error = true })) do
    res[#res + 1] = { path = path }
  end

  for _, path in ipairs(self:arc({ 'ls-files', '-d' }, { ignore_error = true })) do
    res[#res + 1] = { path = path, deleted = true }
  end

  if include_untracked then
    for _, path in ipairs(self:arc({ 'ls-files', '-o' }, { ignore_error = true })) do
      res[#res + 1] = { path = path }
    end
  end

  return res
end

--- @async
--- Translate the handful of git command lines gitsigns issues directly.
---
--- Only for those hard-coded call sites (actions/show_commit.lua:106,
--- actions/blame_line.lua:155, git.lua:143). arcsigns' own code uses :arc().
--- @param args string[]
--- @param spec? ArcSigns.JobSpec
--- @return string[] stdout, string? stderr, integer code
function M:command(args, spec)
  local translate = require('arcsigns.translate')[args[1]]
  if translate then
    return translate(self, args, spec)
  end

  log.eprintf('arcsigns: unsupported git command: %s', table.concat(args, ' '))
  return {}, nil, 0
end

return M
