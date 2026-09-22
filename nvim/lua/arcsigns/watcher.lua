--- Watching an arc metadata directory for index/HEAD changes.
---
--- Same shape as gitsigns/git/repo/repo/watcher.lua: fs_event with an fs_poll
--- fallback, trailing debounce, weak self-references so a dropped repo can be
--- collected. Two differences:
---
---   * we watch the store path (~/.arc/stores/<mangled>/.arc) rather than
---     <toplevel>/.arc — the latter is a different, FUSE-backed inode;
---   * an allow-list filters events, because the arc daemon writes logs/,
---     traces/, arc.pid and port constantly.

local debounce_trailing = require('gitsigns.debounce').debounce_trailing
local log = require('gitsigns.debug.log')
local util = require('gitsigns.util')

local uv = vim.uv or vim.loop ---@diagnostic disable-line: deprecated
local Path = util.Path

local FS_EVENT = 'fs_event'
local FS_POLL = 'fs_poll'
local FS_POLL_INTERVAL = 500

--- Files whose changes actually mean something to us.
local INTERESTING = {
  HEAD = true,
  TREE = true,
  stage = true,
  ORIG_HEAD = true,
}

--- @param handle uv.uv_fs_event_t|uv.uv_fs_poll_t
local function close_handle(handle)
  if handle:is_closing() then
    return
  end
  handle:stop()
  handle:close()
end

--- @param path string
--- @return string?
local function poll_fingerprint(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end

  local mtime = stat.mtime or {}
  return table.concat({
    tostring(stat.size or -1),
    tostring(mtime.sec or -1),
    tostring(mtime.nsec or -1),
  }, ':')
end

--- @param filename string?
--- @return boolean
local function should_notify(filename)
  if not filename then
    -- luv sometimes passes nil; assume it mattered.
    return true
  end

  if INTERESTING[filename] or vim.startswith(filename, 'refs/') or filename == 'refs' then
    log.dprintf("arcsigns: arc dir update: '%s'", filename)
    return true
  end

  return false
end

--- @class ArcSigns.Watcher
--- @field private base string Directory being watched
--- @field private update_callbacks fun()[]
--- @field private notify_debounced fun()
--- @field private handles table<string, uv.uv_fs_event_t|uv.uv_fs_poll_t>
--- @field private head_ref? string
--- @field private _backend 'fs_event'|'fs_poll'
--- @field private _fingerprints table<string, string?>
--- @field private _closed? true
--- @field private _gc userdata?
local Watcher = {}
Watcher.__index = Watcher

local M = {}

--- @param mount ArcSigns.Mount
--- @return ArcSigns.Watcher?
function M.new(mount)
  local base = mount.store or mount.arcdir
  if not Path.is_dir(base) then
    log.eprintf('arcsigns: cannot watch %s', base)
    return nil
  end

  local self = setmetatable({}, Watcher)
  self.base = base
  self.update_callbacks = {}
  self.handles = {}
  self._backend = FS_EVENT
  self._fingerprints = {}

  local weak_self = util.weak_ref(self)
  self.notify_debounced = debounce_trailing(200, function()
    local watcher = weak_self.ref
    if watcher then
      watcher:_notify_callbacks()
    end
  end)

  local handles = self.handles
  self._gc = util.gc_proxy(function()
    for _, handle in pairs(handles) do
      close_handle(handle)
    end
  end)

  self:_sync_watches()

  return self
end

function Watcher:close()
  if self._closed then
    return
  end
  self._closed = true
  self.update_callbacks = {}
  for path in pairs(self.handles) do
    self:_drop(path)
  end
end

--- @private
--- @param path string
function Watcher:_drop(path)
  local handle = self.handles[path]
  if not handle then
    return
  end
  close_handle(handle)
  self.handles[path] = nil
end

--- @private
--- @return string[]
function Watcher:_targets()
  if self._backend == FS_EVENT then
    local targets = { self.base }
    if self.head_ref then
      local dir = vim.fs.dirname(self.head_ref)
      if dir and dir ~= '.' then
        targets[#targets + 1] = vim.fs.joinpath(self.base, dir)
      end
    end
    return targets
  end

  local targets = {
    vim.fs.joinpath(self.base, 'HEAD'),
    vim.fs.joinpath(self.base, 'TREE'),
    vim.fs.joinpath(self.base, 'stage'),
  }
  if self.head_ref then
    targets[#targets + 1] = vim.fs.joinpath(self.base, self.head_ref)
  end
  return targets
end

--- @private
--- @param err string
--- @return false
function Watcher:_fallback_to_poll(err)
  log.dprintf('arcsigns: fs_event failed (%s), falling back to fs_poll', err)

  self._backend = FS_POLL
  self._fingerprints = {}
  for path in pairs(self.handles) do
    self:_drop(path)
  end
  self:_sync_watches()
  self.notify_debounced()
  return false
end

--- @private
--- @param path string
--- @return boolean
function Watcher:_start(path)
  local is_event = self._backend == FS_EVENT
  local handle = (is_event and uv.new_fs_event or uv.new_fs_poll)()
  if not handle then
    return is_event and self:_fallback_to_poll('handle creation failed') or false
  end

  self.handles[path] = handle

  local weak_self = util.weak_ref(self)
  local callback = function(err, arg1)
    local watcher = weak_self.ref
    if not watcher or watcher._closed or watcher.handles[path] ~= handle then
      return
    end

    if err then
      if is_event then
        watcher:_fallback_to_poll(err)
      else
        watcher:_drop(path)
      end
      return
    end

    local notify
    if is_event then
      notify = should_notify(arg1)
    else
      notify = watcher:_poll_changed()
      watcher:_sync_watches()
    end

    if notify then
      watcher.notify_debounced()
    end
  end

  log.dprintf('arcsigns: starting %s on %s', self._backend, path)
  local ok, err = handle:start(path, is_event and {} or FS_POLL_INTERVAL, callback) ---@diagnostic disable-line: param-type-mismatch

  if ok ~= nil then
    return true
  end

  self:_drop(path)
  return is_event and self:_fallback_to_poll(tostring(err)) or false
end

--- @private
--- @return boolean
function Watcher:_poll_changed()
  for target, previous in pairs(self._fingerprints) do
    if previous ~= poll_fingerprint(target) then
      return true
    end
  end
  return false
end

--- @private
function Watcher:_sync_watches()
  if self._closed then
    return
  end

  local is_event = self._backend == FS_EVENT
  local targets = self:_targets()

  local wanted = {} --- @type table<string, true>
  local fingerprints = (not is_event) and {} or nil --- @type table<string, string?>?

  for _, target in ipairs(targets) do
    if fingerprints then
      fingerprints[target] = poll_fingerprint(target)
      -- Poll the parent while the file is missing.
      wanted[Path.exists(target) and target or vim.fs.dirname(target)] = true
    elseif Path.is_dir(target) then
      wanted[target] = true
    end
  end

  for path in pairs(self.handles) do
    if not wanted[path] then
      self:_drop(path)
    end
  end

  for path in pairs(wanted) do
    if not self.handles[path] then
      if not self:_start(path) then
        return
      end
    end
  end

  if fingerprints then
    self._fingerprints = fingerprints
  end
end

--- @param head_ref? string
function Watcher:set_head_ref(head_ref)
  if self.head_ref == head_ref then
    return
  end
  self.head_ref = head_ref
  self:_sync_watches()
end

--- @param callback fun()
--- @return fun() deregister
function Watcher:on_update(callback)
  -- Insertion order matters: slot 1 belongs to the repo itself and must run
  -- before the buffer callbacks.
  table.insert(self.update_callbacks, callback)
  return function()
    for i, cb in ipairs(self.update_callbacks) do
      if cb == callback then
        table.remove(self.update_callbacks, i)
        break
      end
    end
  end
end

--- @private
function Watcher:_notify_callbacks()
  if self._closed then
    return
  end

  vim.schedule(function()
    for _, cb in ipairs(self.update_callbacks) do
      local ok, err = pcall(cb)
      if not ok then
        log.eprintf('arcsigns: watcher callback error: %s', err)
      end
    end
  end)
end

return M
