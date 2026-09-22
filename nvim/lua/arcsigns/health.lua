--- :checkhealth arcsigns
---
--- arcsigns leans on gitsigns internals that carry no compatibility promise, so
--- the most useful thing this can do is name every assumption and say whether
--- it still holds.

local health = vim.health

local M = {}

--- Symbols we depend on: module -> list of dotted paths.
local REQUIRED = {
  ['gitsigns.async'] = { 'wrap', 'schedule', 'semaphore', 'run' },
  ['gitsigns.system'] = { 'system' },
  ['gitsigns.util'] = { 'Path.is_abs', 'gc_proxy', 'weak_ref', 'norm_base' },
  ['gitsigns.hunks'] = { 'apply_to_text' },
  ['gitsigns.git.blame'] = { 'get_blame_nc' },
  ['gitsigns.debounce'] = { 'debounce_trailing' },
  ['gitsigns.debug.log'] = { 'dprint', 'dprintf', 'eprintf' },
  ['gitsigns.cache'] = { 'cache' },
}

--- @param tbl table
--- @param path string
--- @return boolean
local function has(tbl, path)
  local cur = tbl
  for part in path:gmatch('[^.]+') do
    if type(cur) ~= 'table' or cur[part] == nil then
      return false
    end
    cur = cur[part]
  end
  return true
end

local function check_arc()
  health.start('arc')

  local bin = require('arcsigns.config').get().arc_bin
  if vim.fn.executable(bin) == 0 then
    health.error(('`%s` is not executable'):format(bin))
    return
  end

  local version = vim.system({ bin, '--version' }, { text = true }):wait()
  health.ok(('%s: %s'):format(bin, vim.trim(version.stdout or '?')))

  local add_help = vim.system({ bin, 'add', '--help' }, { text = true }):wait()
  if (add_help.stdout or ''):match('%-F%s+path') then
    health.ok('`arc add -F -` is available (partial staging works)')
  else
    health.error(
      '`arc add -F -` is missing',
      { 'Staging hunks will fail; stage whole files with `arc add <file>` instead' }
    )
  end

  local mount_points = vim.fs.joinpath(assert(vim.env.HOME), '.arc', 'mount-points')
  if vim.uv.fs_stat(mount_points) then
    health.ok(('%s is readable'):format(mount_points))
  else
    health.warn(
      ('%s is missing'):format(mount_points),
      { 'Mounted working copies will only be found by walking up for .arc' }
    )
  end

  if require('arcsigns.detect').disabled() then
    health.error('arcsigns disabled itself this session; see :messages')
  end
end

local function check_gitsigns()
  health.start('gitsigns integration')

  if package.loaded['gitsigns.git'] == require('arcsigns.router') then
    health.ok('the gitsigns.git router is installed')
  else
    health.error(
      'the gitsigns.git router is NOT installed',
      { 'require("arcsigns").setup() must run before require("lazy").setup()' }
    )
  end

  local ok = pcall(function()
    return require('arcsigns.compat').real_git().Obj.new
  end)
  if ok then
    health.ok('the real gitsigns.git is still reachable (git repos keep working)')
  else
    health.error('cannot load the real gitsigns.git')
  end

  local missing = {} --- @type string[]
  for name, paths in pairs(REQUIRED) do
    local loaded, mod = pcall(require, name)
    if not loaded then
      missing[#missing + 1] = name .. ' (module)'
    else
      for _, path in ipairs(paths) do
        if not has(mod, path) then
          missing[#missing + 1] = name .. '.' .. path
        end
      end
    end
  end

  if #missing == 0 then
    health.ok('every gitsigns internal arcsigns relies on is present')
  else
    health.error('gitsigns internals have moved', missing)
  end

  local diff_opts = require('gitsigns.config').config.diff_opts
  if diff_opts.internal then
    health.ok("diff_opts.internal is on (no external `git diff` is spawned)")
  else
    health.warn(
      'diff_opts.internal is off, so gitsigns diffs through `git diff`',
      { "Add 'internal' to 'diffopt', or pass diff_opts = { internal = true } to gitsigns.setup" }
    )
  end
end

--- BlameInfo and CommitInfo get merged with vim.tbl_extend('error', ...) in
--- util.convert_blame_info, so overlapping keys would raise at blame time.
local function check_blame_shape()
  health.start('blame structures')

  local blame_info = {
    orig_lnum = 1,
    final_lnum = 1,
    filename = 'x',
    previous_filename = 'x',
    previous_sha = 'x',
  }
  local commit_info = {
    sha = 'x',
    abbrev_sha = 'x',
    author = 'x',
    author_mail = 'x',
    author_time = 0,
    author_tz = '+0000',
    committer = 'x',
    committer_mail = 'x',
    committer_time = 0,
    committer_tz = '+0000',
    summary = 'x',
  }

  local overlap = {} --- @type string[]
  for k in pairs(commit_info) do
    if blame_info[k] ~= nil then
      overlap[#overlap + 1] = k
    end
  end

  if #overlap == 0 then
    health.ok('BlameInfo and CommitInfo keys do not overlap')
  else
    health.error('BlameInfo and CommitInfo keys overlap', overlap)
  end
end

function M.check()
  check_arc()
  check_gitsigns()
  check_blame_shape()
end

return M
