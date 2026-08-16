--- Writing the arc index.
---
--- arc has no `apply --cached`, `hash-object` or `update-index`, so a hunk
--- cannot be staged as a patch. What it does have is `arc add -F -`, which
--- stages content read from stdin without touching the working tree. So we
--- compute the new index contents in Lua — current index plus the selected
--- hunks — and hand the whole file over.
---
--- That flag is documented as "USE WITH CAUTION, may become deprecated at any
--- moment", hence the capability probe and the read-back check.

local async = require('gitsigns.async')
local Hunks = require('gitsigns.hunks')

local config = require('arcsigns.config')

local M = {}

local CAPABILITY_ERR = table.concat({
  'arcsigns: this arc build has no `arc add -F -`, so hunks cannot be staged.',
  'Stage the whole file from a terminal with `arc add <file>`.',
  'See :checkhealth arcsigns',
}, '\n')

--- @type boolean?
local can_stage

local sleep = async.wrap(2, function(duration, cb)
  vim.defer_fn(cb, duration)
end)

--- @param file string
local function autocmd_changed(file)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds('User', {
      pattern = 'GitSignsChanged',
      modeline = false,
      data = { file = file },
    })
  end)
end

--- @async
--- @param repo ArcSigns.Repo
--- @return boolean
function M.can_stage(repo)
  if can_stage == nil then
    local out = repo:arc({ 'add', '--help' }, { ignore_error = true })
    can_stage = table.concat(out, '\n'):match('%-F%s+path') ~= nil
  end
  return can_stage
end

--- @async
--- Replace the file's index contents wholesale.
--- @param obj ArcSigns.Obj
--- @param lines string[]
--- @return string? err
function M.write_index(obj, lines)
  local relpath = assert(obj.relpath)
  if relpath:sub(1, 1) == '-' then
    relpath = './' .. relpath
  end

  -- stdin as a string, not a list: vim.system appends a newline after every
  -- list element (system/compat.lua:75-79), which would grow the file by one
  -- byte each time. `lines` already carries a trailing '' when the blob ends
  -- with a newline, so concat reproduces it exactly.
  local content = table.concat(lines, '\n')

  local _, stderr, code = obj.repo:arc({ 'add', '-F', '-', relpath }, {
    stdin = content,
    text = false,
    ignore_error = true,
  })

  if code ~= 0 then
    return ('arcsigns: `arc add -F -` exited %d: %s'):format(code, stderr or '')
  end

  if config.get().stage.verify then
    local after = obj.repo:get_show_text(':' .. relpath, obj.encoding)
    if table.concat(after, '\n') ~= content then
      return 'arcsigns: the index does not match what was written; '
        .. '`arc add -F -` may have changed meaning. Check `arc status`.'
    end
  end

  -- Staging churns .arc; give the watcher a moment to settle, as gitsigns does
  -- for git (git.lua:226).
  sleep(100)
  autocmd_changed(obj.file)
end

--- @async
--- @param obj ArcSigns.Obj
--- @param hunks Gitsigns.Hunk.Hunk[]
--- @param invert? boolean
--- @return string? err
function M.stage_hunks(obj, hunks, invert)
  if not M.can_stage(obj.repo) then
    return CAPABILITY_ERR
  end

  -- The hunks are expressed against the current index, so that is the base.
  local text = obj.object_name and obj:get_show_text() or { '' }

  -- Bottom-up: every hunk's removed.start refers to the original index text,
  -- so applying top-down would shift the ones below it.
  local sorted = vim.deepcopy(hunks)
  table.sort(sorted, function(a, b)
    return a.removed.start > b.removed.start
  end)

  for _, hunk in ipairs(sorted) do
    text = Hunks.apply_to_text(text, hunk, invert)
  end

  return M.write_index(obj, text)
end

--- @async
--- @param obj ArcSigns.Obj
--- @param lines string[]
--- @return string? err
function M.stage_lines(obj, lines)
  if not M.can_stage(obj.repo) then
    return CAPABILITY_ERR
  end
  return M.write_index(obj, lines)
end

--- @async
--- @param obj ArcSigns.Obj
function M.unstage_file(obj)
  obj.repo:arc({ 'reset', 'HEAD', assert(obj.relpath) })
  autocmd_changed(obj.file)
end

return M
