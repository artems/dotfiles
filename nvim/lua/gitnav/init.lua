--- Navigate between changed files in Git and Arc working copies.

local M = {}

local pending ---@type { win: integer, buf: integer, current: string?, delta: integer }?

---@class GitNav.Entry
---@field file string
---@field status string

---@param message string
---@param level integer
local function notify(message, level)
  Snacks.notify(message, { title = 'Changed files', level = level })
end

---@param stdout string
---@param root string
---@return GitNav.Entry[]
local function parse_git_status(stdout, root)
  local entries = {}
  local records = vim.split(stdout, '\0', { plain = true })
  local index = 1

  while index <= #records do
    local status, file = records[index]:match('^(..) (.+)$')
    if status and file then
      entries[#entries + 1] = {
        file = vim.fs.normalize(root .. '/' .. file),
        status = status,
      }

      -- With `-z`, a rename/copy is followed by its original path without
      -- another status prefix. The destination above is the navigable file.
      if status:find('[RC]') then
        index = index + 1
      end
    end
    index = index + 1
  end

  return entries
end

---@param root string
---@param on_done fun(entries: GitNav.Entry[]?, err: string?)
local function git_status(root, on_done)
  local ok, handle = pcall(vim.system, {
    'git',
    '--no-pager',
    '--no-optional-locks',
    'status',
    '--porcelain=v1',
    '-z',
    '-uall',
  }, { cwd = root, timeout = 10000 }, function(result)
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local err = stderr ~= '' and vim.trim(stderr) or 'git status failed'
      return on_done(nil, err)
    end
    on_done(parse_git_status(result.stdout or '', root))
  end)

  if not ok then
    vim.schedule(function()
      on_done(nil, tostring(handle))
    end)
  end
end

---@param path string
---@param on_done fun(root: string?, entries: GitNav.Entry[]?, err: string?)
local function status(path, on_done)
  local arc_root = require('arcsnacks.route').root(path)
  if arc_root then
    require('arcsnacks.status').fetch(arc_root, { untracked = 'all' }, function(entries, err)
      on_done(arc_root, entries, err)
    end)
    return
  end

  local root = Snacks.git.get_root(path)
  if not root then
    on_done(nil)
    return
  end
  git_status(root, function(entries, err)
    on_done(root, entries, err)
  end)
end

---@param entries GitNav.Entry[]
---@return string[]
local function files(entries)
  local seen = {}
  local ret = {}

  for _, entry in ipairs(entries) do
    local file = vim.fs.normalize((entry.file:gsub('/$', '')))
    local stat = (vim.uv or vim.loop).fs_stat(file)
    if stat and stat.type ~= 'directory' and not seen[file] then
      seen[file] = true
      ret[#ret + 1] = file
    end
  end

  table.sort(ret)
  return ret
end

---@param changed string[]
---@param current string?
---@param delta integer
---@return string
local function target(changed, current, delta)
  local direction = delta > 0 and 1 or -1
  local start
  if current then
    for index, file in ipairs(changed) do
      if file == current then
        start = index
        break
      elseif direction > 0 and not start and file > current then
        start = index - 1
      elseif direction < 0 and file < current then
        start = index + 1
      end
    end
  end

  start = start or (direction > 0 and 0 or 1)
  return changed[(start - 1 + delta) % #changed + 1]
end

---@param direction integer
---@param count? integer
function M.jump(direction, count)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(0)
  local current = name ~= '' and vim.fs.normalize(name) or nil
  local path = current or (vim.uv or vim.loop).cwd()
  if not path then
    return
  end

  local delta = direction * (count or 1)
  if pending and pending.win == win and pending.buf == buf then
    pending.delta = pending.delta + delta
    return
  end

  local request = {
    win = win,
    buf = buf,
    current = current,
    delta = delta,
  }
  pending = request

  status(path, function(root, entries, err)
    vim.schedule(function()
      if pending ~= request then
        return
      end
      pending = nil

      if request.delta == 0 then
        return
      elseif err then
        notify(err, vim.log.levels.ERROR)
        return
      elseif not root then
        notify('Not in a Git or Arc working copy', vim.log.levels.WARN)
        return
      end

      local changed = files(entries or {})
      if #changed == 0 then
        notify('No changed files', vim.log.levels.INFO)
        return
      elseif not vim.api.nvim_win_is_valid(request.win)
        or vim.api.nvim_win_get_buf(request.win) ~= request.buf
      then
        return
      end

      local destination = target(changed, request.current, request.delta)
      vim.api.nvim_win_call(request.win, function()
        local ok, edit_err = pcall(vim.api.nvim_cmd, { cmd = 'edit', args = { destination } }, {})
        if not ok then
          notify(tostring(edit_err), vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

---@param count? integer
function M.next(count)
  M.jump(1, count)
end

---@param count? integer
function M.prev(count)
  M.jump(-1, count)
end

return M
