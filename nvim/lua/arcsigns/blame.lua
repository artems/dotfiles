--- Blame via `arc blame --json`.
---
--- Two things arc cannot do that git can:
---
---   * there is no --contents, so the buffer's unsaved state cannot be blamed.
---     We diff the buffer against the blamed revision and translate line
---     numbers, reporting lines inside a hunk as "Not Committed Yet" — which is
---     what gitsigns would show anyway (cache.lua:229 skips them).
---   * it can be slow: 0.4s on an ordinary file but 25-40s on one with a huge
---     history, so calls are given a timeout and slow files are remembered.

local log = require('gitsigns.debug.log')
local run_diff = require('gitsigns.diff')

local config = require('arcsigns.config')

local uv = vim.uv or vim.loop ---@diagnostic disable-line: deprecated

local M = {}

--- relpath -> true once a whole-file blame proved too slow to repeat.
--- @type table<string, boolean>
local slow = {}

--- Parse arc's ISO-8601 timestamps, e.g. '2024-03-08T21:33:26+03:00'.
--- @param iso? string
--- @return integer time Unix timestamp
--- @return string tz e.g. '+0300'
local function parse_iso8601(iso)
  local y, mo, d, h, mi, s, rest =
    (iso or ''):match('^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)(.*)$')

  if not y then
    return os.time(), '+0000'
  end

  local t = {
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(s),
    isdst = false,
  }

  -- os.time() reads the table as local time and Lua has no timegm, so undo the
  -- local offset before applying the one arc reported.
  local as_local = os.time(t)
  local utc_view = os.date('!*t', as_local) --[[@as osdateparam]]
  utc_view.isdst = false
  local epoch = as_local + os.difftime(as_local, os.time(utc_view))

  local sign, th, tm = rest:match('^([+-])(%d%d):?(%d%d)$')
  if not sign then
    return epoch, '+0000' -- 'Z' or nothing
  end

  local offset = (tonumber(th) * 3600 + tonumber(tm) * 60) * (sign == '-' and -1 or 1)
  return epoch - offset, ('%s%s%s'):format(sign, th, tm)
end

--- @param login? string
--- @return string
local function mail(login)
  return login and ('<%s@yandex-team.ru>'):format(login) or '<unknown>'
end

--- @param c table Entry from arc blame's `commits` array
--- @return Gitsigns.CommitInfo
local function to_commit_info(c)
  local time, tz = parse_iso8601(c.date)
  local address = mail(c.author)

  -- Keys here must not overlap Gitsigns.BlameInfo's: util.convert_blame_info
  -- merges the two with vim.tbl_extend('error', ...) (util.lua:377).
  return {
    sha = c.commit,
    abbrev_sha = c.commit and c.commit:sub(1, 8) or ('0'):rep(8),
    author = c.author,
    author_mail = address,
    author_time = time,
    author_tz = tz,
    committer = c.author,
    committer_mail = address,
    committer_time = time,
    committer_tz = tz,
    summary = vim.split(c.message or '', '\n')[1] or '',
  }
end

--- @param obj ArcSigns.Obj
--- @param lnum integer
--- @return Gitsigns.BlameInfo
local function not_committed(obj, lnum)
  return require('gitsigns.git.blame').get_blame_nc(obj.relpath or obj.file, lnum)
end

--- Map buffer line numbers onto the revision arc actually blames.
---
--- @param obj ArcSigns.Obj
--- @param contents? string[]
--- @param revision? string
--- @return fun(lnum: integer): integer? to_base
--- @return fun(lnum: integer): integer to_buf
local function line_map(obj, contents, revision)
  local identity = function(lnum)
    return lnum
  end

  if not contents then
    return identity, identity
  end

  local base = obj:get_show_text(revision or 'HEAD')
  if #base == 0 then
    return identity, identity
  end

  local hunks = run_diff(base, contents, false)
  if not hunks or #hunks == 0 then
    return identity, identity
  end

  --- Lines above `lnum` shift it by (added - removed).
  --- @param lnum integer
  --- @return integer delta
  --- @return boolean inside
  local function delta_at(lnum)
    local delta = 0
    for _, h in ipairs(hunks) do
      local astart, acount = h.added.start, h.added.count
      if acount > 0 and lnum >= astart and lnum <= astart + acount - 1 then
        return delta, true
      end

      local above = acount > 0 and (astart + acount - 1 < lnum) or (astart < lnum)
      if above then
        delta = delta + acount - h.removed.count
      end
    end
    return delta, false
  end

  local to_base = function(lnum)
    local delta, inside = delta_at(lnum)
    if inside then
      return nil
    end
    return lnum - delta
  end

  local to_buf = function(base_lnum)
    -- Walk the hunks in base coordinates to invert the mapping.
    local delta = 0
    for _, h in ipairs(hunks) do
      local rstart, rcount = h.removed.start, h.removed.count
      local above = rcount > 0 and (rstart + rcount - 1 < base_lnum) or (rstart < base_lnum)
      if above then
        delta = delta + h.added.count - rcount
      end
    end
    return base_lnum + delta
  end

  return to_base, to_buf
end

--- @async
--- @param obj ArcSigns.Obj
--- @param args string[]
--- @return table?
local function blame_json(obj, args)
  local cfg = config.get().blame
  local started = uv.hrtime()

  local res, err = obj.repo:arc_json(args, { timeout = cfg.timeout_ms })

  local elapsed = (uv.hrtime() - started) / 1e6
  if elapsed > cfg.slow_threshold_ms then
    log.dprintf('arcsigns: blame of %s took %dms', obj.relpath, elapsed)
  end

  if not res then
    vim.notify_once(
      ('arcsigns: `arc %s` failed or timed out (%s)'):format(table.concat(args, ' '), err or '?'),
      vim.log.levels.WARN
    )
    return nil
  end

  return { res = res, elapsed = elapsed }
end

--- @async
--- @param obj ArcSigns.Obj
--- @param contents? string[]
--- @param lnum? integer|[integer, integer]
--- @param revision? string
--- @param _opts? Gitsigns.BlameOpts
--- @return table<integer, Gitsigns.BlameInfo?>
--- @return table<string, Gitsigns.CommitInfo?>
function M.run_blame(obj, contents, lnum, revision, _opts)
  local ret = {} --- @type table<integer, Gitsigns.BlameInfo?>
  local commits = {} --- @type table<string, Gitsigns.CommitInfo?>

  local cfg = config.get().blame

  -- Untracked, or a repo with no commits: nothing is attributable.
  if not cfg.enabled or not obj.object_name or obj.repo.abbrev_head == '' then
    if contents then
      for i = 1, #contents do
        ret[i] = not_committed(obj, i)
      end
    end
    return ret, commits
  end

  local relpath = assert(obj.relpath)
  local to_base, to_buf = line_map(obj, contents, revision)

  local args = { 'blame' }

  --- @type integer?, integer?
  local from, to
  if type(lnum) == 'table' then
    from, to = lnum[1], lnum[2]
  elseif lnum then
    from, to = lnum, lnum
  end

  if from and to then
    local base_from, base_to = to_base(from), to_base(to)

    if not base_from or not base_to then
      -- The requested line only exists in the buffer.
      for i = from, to do
        ret[i] = not_committed(obj, i)
      end
      return ret, commits
    end

    args[#args + 1] = ('-L%d,%d'):format(base_from, base_to)
  elseif slow[relpath] then
    vim.notify_once(
      ('arcsigns: skipping whole-file blame of %s (previous run took over %dms); '
        .. 'blame a single line instead'):format(relpath, cfg.slow_threshold_ms),
      vim.log.levels.WARN
    )
    return ret, commits
  end

  if revision and require('arcsigns.router').Repo.from_tree(revision) then
    args[#args + 1] = revision
  end

  args[#args + 1] = relpath

  local out = blame_json(obj, args)
  if not out then
    return ret, commits
  end

  if not from then
    slow[relpath] = out.elapsed > cfg.slow_threshold_ms or nil
  end

  local blame = out.res
  local by_sha = {} --- @type table<string, Gitsigns.CommitInfo>
  for _, c in ipairs(blame.commits or {}) do
    local info = to_commit_info(c)
    by_sha[c.commit] = info
    commits[c.commit] = info
  end

  local paths = {} --- @type table<string, string>
  for _, c in ipairs(blame.commits or {}) do
    paths[c.commit] = c.path
  end

  for _, a in ipairs(blame.annotation or {}) do
    local commit = by_sha[a.commit]
    if not commit then
      commit = to_commit_info(a)
      by_sha[a.commit] = commit
      commits[a.commit] = commit
    end

    local buf_lnum = to_buf(a.line)
    ret[buf_lnum] = {
      -- arc reports no line number in the originating commit; the blamed
      -- revision's own numbering is the closest thing we have.
      orig_lnum = a.line,
      final_lnum = buf_lnum,
      commit = commit,
      filename = paths[a.commit] or relpath,
    }
  end

  -- Lines that only exist in the buffer never reach arc, so fill them in.
  if contents and not from then
    for i = 1, #contents do
      if not ret[i] then
        ret[i] = not_committed(obj, i)
      end
    end
  end

  return ret, commits
end

--- Forget which files were slow (used by :ArcsignsReload).
function M.reset_slow()
  slow = {}
end

return M
