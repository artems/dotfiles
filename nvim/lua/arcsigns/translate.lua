--- Translating the few git command lines gitsigns issues directly.
---
--- gitsigns reaches past the Repo abstraction in exactly three places:
---   actions/show_commit.lua:106  show --unified=0 --format=format:<SHOW_FORMAT>
---   actions/blame_line.lua:155   show -s --format=%B <sha>
---   git.lua:143 (unstage_file)   reset <file>
--- The last one we implement ourselves, so only the two `show` forms land here.

local M = {}

--- @param repo ArcSigns.Repo
--- @param rev string
--- @return table? commit  Decoded `arc log -n1 --json` entry
local function log_entry(repo, rev)
  local entries = repo:arc_json({ 'log', '-n1', '--no-walk', rev })
  return entries and entries[1] or nil
end

--- @param login? string
--- @return string
local function mail(login)
  return login and ('<%s@yandex-team.ru>'):format(login) or '<unknown>'
end

--- Rebuild the six header lines show_commit.lua expects, then the message and
--- the diff. Line 6 must start with 'encoding' — show_commit.lua:114 indexes
--- res[6] unconditionally and drops it unless it reads 'encoding unknown'.
--- @param repo ArcSigns.Repo
--- @param rev string
--- @param unified? string
--- @return string[]
local function show_commit(repo, rev, unified)
  local commit = log_entry(repo, rev)
  if not commit then
    return { ('arcsigns: no such revision: %s'):format(rev) }
  end

  local who = ('%s %s %s'):format(commit.author, mail(commit.author), commit.date)

  local res = {
    'commit ' .. commit.commit,
    'tree ', -- arc exposes no tree hash for a commit
    'parent ' .. table.concat(commit.parents or {}, ' '),
    'author ' .. who,
    'committer ' .. who,
    'encoding unknown',
    '',
  }

  vim.list_extend(res, vim.split(commit.message or '', '\n'))

  local args = { 'show', '--git', '--unified=' .. (unified or '0'), rev }
  local diff = repo:arc(args, { ignore_error = true })

  -- Drop arc's own header: everything before the first `diff --git`.
  local from
  for i, line in ipairs(diff) do
    if vim.startswith(line, 'diff --git') then
      from = i
      break
    end
  end

  if from then
    res[#res + 1] = ''
    vim.list_extend(res, vim.list_slice(diff, from))
  end

  return res
end

--- @async
--- @param repo ArcSigns.Repo
--- @param args string[]
--- @return string[] stdout, string? stderr, integer code
function M.show(repo, args)
  local format, rev, unified
  local quiet = false

  for i, a in ipairs(args) do
    if a == '-s' or a == '--quiet' then
      quiet = true
    elseif a:match('^%-%-format=') then
      format = a:sub(#'--format=' + 1)
    elseif a:match('^%-%-unified=') then
      unified = a:match('=(%d+)')
    elseif i > 1 and a:sub(1, 1) ~= '-' then
      rev = a
    end
  end

  if not rev then
    return {}, 'arcsigns: no revision in `show`', 1
  end

  if quiet and format == '%B' then
    local commit = log_entry(repo, rev)
    return vim.split(commit and commit.message or '', '\n'), nil, 0
  end

  if format and vim.startswith(format, 'format:') then
    return show_commit(repo, rev, unified), nil, 0
  end

  return repo:arc(args, { ignore_error = true })
end

--- @async
--- @param repo ArcSigns.Repo
--- @param args string[]
--- @return string[] stdout, string? stderr, integer code
function M.reset(repo, args)
  local relpath = args[2] and repo:relpath(args[2])
  if not relpath then
    return {}, 'arcsigns: `reset` outside the working copy', 1
  end

  -- Explicit HEAD disambiguates `arc reset [BRANCH] [PATH]`. Never --hard.
  return repo:arc({ 'reset', 'HEAD', relpath })
end

return M
