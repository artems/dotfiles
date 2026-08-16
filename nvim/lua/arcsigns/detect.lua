--- Deciding whether a path belongs to an arc working copy.
---
--- This runs on every BufRead via gitsigns' attach, so the hot path must cost
--- nothing: a full-path cache (including negative entries) in front of a
--- string-prefix match against ~/.arc/mount-points. Only if that misses do we
--- touch the filesystem, and only when detect_local_repos is on.

local uv = vim.uv or vim.loop ---@diagnostic disable-line: deprecated

local config = require('arcsigns.config')

--- @class ArcSigns.Mount
--- @field toplevel string Working copy root, normalized, no trailing slash
--- @field arcdir string `<toplevel>/.arc` — what gitsigns sees as `gitdir`
--- @field store? string `<store>/.arc` — the real on-disk path, for the watcher

local M = {}

--- @type ArcSigns.Mount[]?
local mounts

--- @type integer?
local mounts_mtime

--- @type integer
local mounts_checked_at = 0

--- @type table<string, ArcSigns.Mount|false>
local path_cache = {}

--- @type table<string, ArcSigns.Mount|false>
local updir_cache = {}

--- Set once arc turns out to be unusable (missing binary, dead daemon).
--- From then on nothing is arc and gitsigns degrades to plain git.
local disabled = false

--- @param path string
--- @return string
local function normalize(path)
  path = vim.fs.normalize(path)
  -- vim.fs.normalize keeps a trailing slash for '/'; strip it elsewhere.
  if #path > 1 and path:sub(-1) == '/' then
    path = path:sub(1, -2)
  end
  return path
end

--- Parse ~/.arc/mount-points.
---
--- Format (protobuf text):
---     MountPoints {
---       Mount: "/home/user/arcadia"
---       Store: "/home/user/.arc/stores/_home_user_arcadia"
---     }
---
--- A `Mount:` line starts a new entry, a `Store:` line fills in the current one,
--- so both a single block with several pairs and several blocks work.
--- @param text string
--- @return ArcSigns.Mount[]
local function parse_mount_points(text)
  local res = {} --- @type ArcSigns.Mount[]
  for line in text:gmatch('[^\n]+') do
    local mount = line:match('^%s*Mount:%s*"(.-)"%s*$')
    if mount then
      local toplevel = normalize(mount)
      res[#res + 1] = { toplevel = toplevel, arcdir = toplevel .. '/.arc' }
    else
      local store = line:match('^%s*Store:%s*"(.-)"%s*$')
      if store and res[#res] then
        res[#res].store = normalize(store) .. '/.arc'
      end
    end
  end
  return res
end

--- @return ArcSigns.Mount[]
local function load_mounts()
  local now = uv.now()
  if mounts and (now - mounts_checked_at) < config.get().mounts_ttl_ms then
    return mounts
  end
  mounts_checked_at = now

  local path = vim.fs.joinpath(assert(vim.env.HOME), '.arc', 'mount-points')
  local stat = uv.fs_stat(path)

  if not stat then
    mounts = mounts or {}
    return mounts
  end

  if mounts and mounts_mtime == stat.mtime.sec then
    return mounts
  end

  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    mounts = mounts or {}
    return mounts
  end

  local text = uv.fs_read(fd, stat.size, 0) or ''
  uv.fs_close(fd)

  mounts_mtime = stat.mtime.sec
  mounts = parse_mount_points(text)

  -- The mount table changed, so cached verdicts may be stale.
  path_cache = {}
  updir_cache = {}

  return mounts
end

--- Is this a real arc metadata directory?
---
--- The mere existence of `.arc` proves nothing: ~/.arc is arc's own config
--- directory, and ~/dotfiles/.arc holds prompt.sh. Every working copy has a
--- HEAD file, so key off that.
--- @param arcdir string
--- @return boolean
local function is_arcdir(arcdir)
  local stat = uv.fs_stat(arcdir .. '/HEAD')
  return stat ~= nil and stat.type == 'file'
end

--- Walk up looking for a .arc directory, for locally created (`arc init`) repos
--- that are absent from mount-points. Memoized per directory.
--- @param path string
--- @return ArcSigns.Mount?
local function find_upward(path)
  local dir = uv.fs_stat(path)
  dir = (dir and dir.type == 'directory') and path or vim.fs.dirname(path)

  local home = normalize(assert(vim.env.HOME))
  local seen = {} --- @type string[]

  while dir and dir ~= '/' and dir ~= '' do
    local cached = updir_cache[dir]
    if cached ~= nil then
      for _, d in ipairs(seen) do
        updir_cache[d] = cached
      end
      return cached or nil
    end

    seen[#seen + 1] = dir

    local arcdir = dir .. '/.arc'
    if is_arcdir(arcdir) then
      local mount = { toplevel = dir, arcdir = arcdir }
      for _, d in ipairs(seen) do
        updir_cache[d] = mount
      end
      return mount
    end

    if dir == home then
      break
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  for _, d in ipairs(seen) do
    updir_cache[d] = false
  end
end

--- Which arc working copy, if any, contains `path`.
--- @param path string Absolute path to a file or directory
--- @return ArcSigns.Mount?
function M.workspace(path)
  if disabled or not path or path == '' then
    return nil
  end

  path = normalize(path)

  local cached = path_cache[path]
  if cached ~= nil then
    return cached or nil
  end

  local res --- @type ArcSigns.Mount?
  for _, mount in ipairs(load_mounts()) do
    if path == mount.toplevel or vim.startswith(path, mount.toplevel .. '/') then
      res = mount
      break
    end
  end

  if not res and config.get().detect_local_repos then
    res = find_upward(path)
  end

  path_cache[path] = res or false
  return res
end

--- Look up a mount by its `<toplevel>/.arc` path.
--- @param arcdir string
--- @return ArcSigns.Mount?
function M.by_arcdir(arcdir)
  arcdir = normalize(arcdir)
  local toplevel = vim.fs.dirname(arcdir)

  for _, mount in ipairs(load_mounts()) do
    if mount.arcdir == arcdir then
      return mount
    end
  end

  -- A local repo, or one that appeared after mount-points was last read.
  if is_arcdir(arcdir) then
    return { toplevel = toplevel, arcdir = arcdir }
  end
end

--- Give up on arc entirely for the rest of the session.
--- @param reason string
function M.disable(reason)
  if disabled then
    return
  end
  disabled = true
  path_cache = {}
  updir_cache = {}
  vim.schedule(function()
    vim.notify(
      ('arcsigns: disabled (%s); gitsigns falls back to git'):format(reason),
      vim.log.levels.WARN
    )
  end)
end

--- @return boolean
function M.disabled()
  return disabled
end

function M.flush()
  mounts = nil
  mounts_mtime = nil
  mounts_checked_at = 0
  path_cache = {}
  updir_cache = {}
end

return M
