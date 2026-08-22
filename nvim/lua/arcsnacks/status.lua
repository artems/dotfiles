--- Turning `arc status --json` into git porcelain v1 XY codes.
---
--- snacks speaks porcelain everywhere downstream of the status call: the
--- explorer merges codes up the tree with Git.merge_status, the formatter maps
--- them to highlight groups, and picker/source/git.git_status() raises an error
--- on any code it cannot parse. Normalising here once therefore keeps every
--- consumer working unmodified.
---
--- `arc status -s` looks closer to git at first glance, but it prints one line
--- per side (`A ` and ` M` for the same file rather than `AM`), spells renames
--- as `old -> new`, has no -z and no quoting. The JSON keeps the two sides
--- apart and gives renames a separate orig_path, so we parse that instead.

local M = {}

--- Index side (X). `arc status --json` names these under "staged".
local STAGED = {
  ['new file'] = 'A',
  modified = 'M',
  deleted = 'D',
  renamed = 'R',
  copied = 'C',
  typechange = 'T',
}

--- Worktree side (Y), under "changed".
local UNSTAGED = {
  modified = 'M',
  deleted = 'D',
  typechange = 'T',
}

--- Sections that mean "both sides are in conflict". arc's own wording has
--- varied between releases, so accept either spelling.
local CONFLICTED = { 'unmerged', 'conflicts' }

--- @param decoded any Whatever `arc status --json` produced
--- @param root string Working copy root, absolute, no trailing slash
--- @return snacks.explorer.git.Status[]
function M.entries(decoded, root)
  local status = type(decoded) == 'table' and decoded.status or nil
  if type(status) ~= 'table' then
    return {}
  end

  local codes = {} --- @type table<string, string[]>
  local order = {} --- @type string[]

  --- @param entry any
  --- @return string[]? code Two single-character slots, X and Y
  local function slot(entry)
    local rel = type(entry) == 'table' and entry.path or nil
    if type(rel) ~= 'string' or rel == '' then
      return nil
    end

    local path = root .. '/' .. rel
    if entry.type == 'directory' then
      -- explorer/git.lua keys directories off a trailing slash.
      path = path .. '/'
    end

    if not codes[path] then
      codes[path] = { ' ', ' ' }
      order[#order + 1] = path
    end
    return codes[path]
  end

  --- @param section any
  --- @param map table<string, string>
  --- @param side integer 1 for the index, 2 for the worktree
  local function collect(section, map, side)
    for _, entry in ipairs(type(section) == 'table' and section or {}) do
      local code = map[entry.status]
      local slots = code and slot(entry)
      if slots then
        slots[side] = code
      end
    end
  end

  collect(status.staged, STAGED, 1)
  collect(status.changed, UNSTAGED, 2)

  for _, entry in ipairs(type(status.untracked) == 'table' and status.untracked or {}) do
    local slots = slot(entry)
    if slots then
      slots[1], slots[2] = '?', '?'
    end
  end

  for _, name in ipairs(CONFLICTED) do
    for _, entry in ipairs(type(status[name]) == 'table' and status[name] or {}) do
      local slots = slot(entry)
      if slots then
        slots[1], slots[2] = 'U', 'U'
      end
    end
  end

  local ret = {} --- @type snacks.explorer.git.Status[]
  for _, path in ipairs(order) do
    local xy = table.concat(codes[path])
    -- An entry we recognised nothing about would be ' ', which git_status()
    -- rejects; drop it rather than crash the picker on a future arc status.
    if xy ~= '  ' then
      ret[#ret + 1] = { status = xy, file = path }
    end
  end
  return ret
end

--- Fetch and normalise the status of a whole working copy.
---
--- `untracked` mirrors git's -u: "normal" collapses a wholly untracked
--- directory into a single entry (what the tree wants), "all" lists every file
--- inside it (what the picker wants).
--- @param root string Working copy root
--- @param opts {untracked?: 'all'|'normal'|'no'}
--- @param on_done fun(entries: snacks.explorer.git.Status[], err: string?)
--- @return vim.SystemObj?
function M.fetch(root, opts, on_done)
  local args = { 'status', '-u', opts.untracked or 'normal' }
  return require('arcsnacks.cmd').json(args, { cwd = root }, function(decoded, err)
    if err then
      return on_done({}, err)
    end
    on_done(M.entries(decoded, root))
  end)
end

return M
