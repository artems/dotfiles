--- Teaching the git-flavoured picker sources to speak arc.
---
--- Four layers get patched, each at the narrowest point that works:
---
---   * Snacks.git.get_root — the single place snacks decides "which repository
---     is this?". Without it every git source falls back to the raw cwd.
---   * picker/source/git — the finders. status and log need real parsing, diff
---     only needs a different argv, and the rest have no arc equivalent.
---   * picker/preview — git_show and git_diff spawn git directly.
---   * picker/util.cmd — the chokepoint every git-touching action goes through.
---
--- Everything checks the path first and delegates to the original when it is
--- not arc, so git repositories behave exactly as before.

local cmd = require('arcsnacks.cmd')
local route = require('arcsnacks.route')

local M = {}

--- History longer than this is not worth decoding: arc will happily walk a
--- decade of trunk, and the picker only ever shows the head of the list.
local LOG_LIMIT = 1000

--- @type boolean
local patched = false

--- @param reason string
local function unsupported(reason)
  Snacks.notify.warn(reason, { title = 'arc' })
end

--- Wait for an arc command from inside a finder coroutine.
---
--- Finders run as snacks Async tasks: suspend yields control back to the picker
--- so the UI keeps breathing, and resume comes from the vim.system callback.
--- If the picker is closed meanwhile the task is aborted, and we kill the arc
--- process rather than leave it grinding through the repository for nobody.
--- @param start fun(done: fun(...)): vim.SystemObj?
--- @return any ...
local function await(start)
  local Async = require('snacks.picker.util.async')
  local async = Async.running()

  local result --- @type table?
  local handle = start(function(...)
    result = { ... }
    if async then
      async:resume()
    end
  end)

  if async and handle then
    async:on('abort', function()
      pcall(function()
        handle:kill('sigterm')
      end)
    end)
  end

  while not result do
    if not async then
      -- Not in a task (never happens from a finder, but keep it honest).
      vim.wait(10)
    elseif async:aborted() then
      return nil
    else
      async:suspend()
    end
  end

  return unpack(result)
end

--- @param args string[]
--- @return string[] argv
local function argv(args)
  local ret = { cmd.bin() }
  vim.list_extend(ret, args)
  return ret
end

local function patch_root()
  local Git = require('snacks.git')
  local orig_get_root = Git.get_root

  --- @param path? number|string
  --- @return string?
  function Git.get_root(path)
    return route.root(path) or orig_get_root(path)
  end
end

local function patch_sources()
  local Git = require('snacks.picker.source.git')
  local Status = require('arcsnacks.status')

  local orig = {
    status = Git.status,
    log = Git.log,
    diff = Git.diff,
    files = Git.files,
    grep = Git.grep,
    branches = Git.branches,
    stash = Git.stash,
  }

  --- @param ctx snacks.picker.finder.ctx
  --- @return string?
  local function root_of(ctx)
    return route.root(ctx.filter.cwd)
  end

  --- @type snacks.picker.finder
  function Git.status(opts, ctx)
    local root = root_of(ctx)
    if not root then
      return orig.status(opts, ctx)
    end
    ctx.picker:set_cwd(root)

    -- opts.ignored is dropped on purpose: arc reports no ignored files at all
    -- (`--ignored` is accepted but never yields `!!`), so there is nothing to
    -- list even when asked.
    return function(cb)
      local entries, err = await(function(done)
        return Status.fetch(root, { untracked = 'all' }, done)
      end)
      if err then
        return Snacks.notify.error('arc status failed:\n' .. err, { title = 'arc' })
      end
      for _, entry in ipairs(entries or {}) do
        local file = route.relative(entry.file, root):gsub('/$', '')
        cb({ text = file, file = file, cwd = root, status = entry.status })
      end
    end
  end

  --- @type snacks.picker.finder
  function Git.log(opts, ctx)
    local file --- @type string?
    if opts.current_line or opts.current_file then
      local name = vim.api.nvim_buf_get_name(ctx.filter.current_buf)
      file = name ~= '' and vim.fs.normalize(name) or nil
    end

    local root = route.root(file or ctx.filter.cwd)
    if not root then
      return orig.log(opts, ctx)
    end

    if opts.current_line then
      -- `git log -L <line>,+1:<file>` has no arc counterpart; arc log takes no
      -- line ranges. Line-level history stays with gitsigns blame (arcsigns).
      unsupported('`arc log` has no -L: line history is unavailable. Use gitsigns blame.')
      return {}
    end

    local args = { 'log', '-n', tostring(LOG_LIMIT) }
    if opts.author then
      vim.list_extend(args, { '--author', opts.author })
    end
    if ctx.filter.search ~= '' then
      vim.list_extend(args, { '-S', ctx.filter.search })
    end
    if file then
      if opts.follow then
        args[#args + 1] = '--follow'
      end
      args[#args + 1] = route.relative(file, root)
    end

    return function(cb)
      local decoded, err = await(function(done)
        return cmd.json(args, { cwd = root }, done)
      end)
      if err then
        return Snacks.notify.error('arc log failed:\n' .. err, { title = 'arc' })
      end

      for _, commit in ipairs(type(decoded) == 'table' and decoded or {}) do
        local hash = commit.commit
        if type(hash) == 'string' then
          local msg = vim.split(commit.message or '', '\n', { plain = true })[1] or ''
          local author = commit.author or ''
          cb({
            text = ('%s %s <%s>'):format(hash:sub(1, 8), msg, author),
            commit = hash,
            msg = msg,
            -- arc dates are ISO 8601; the format only has room for the day.
            date = (commit.date or ''):sub(1, 10),
            author = author,
            file = file,
            files = file and { file } or nil,
            cwd = root,
          })
        end
      end
    end
  end

  --- @type snacks.picker.finder
  function Git.diff(opts, ctx)
    opts = opts or {}
    local root = root_of(ctx)
    if not root then
      return orig.diff(opts, ctx)
    end
    ctx.picker:set_cwd(root)

    local args = { 'diff', '--git', '--no-color' }
    if opts.base then
      -- arc spells `--merge-base <base>` as `-B <from>`; FROM defaults to trunk.
      vim.list_extend(args, { '-B', opts.base })
    end
    if opts.staged then
      args[#args + 1] = '--cached'
    end

    local Diff = require('snacks.picker.source.diff')
    local finders = {} --- @type snacks.picker.finder.result[]
    finders[#finders + 1] = Diff.diff(ctx:opts({ cmd = cmd.bin(), args = args, cwd = root }), ctx)

    if opts.staged == nil and opts.base == nil then
      local staged = vim.list_extend(vim.deepcopy(args), { '--cached' })
      finders[#finders + 1] = Diff.diff(ctx:opts({ cmd = cmd.bin(), args = staged, cwd = root }), ctx)
    end

    return function(cb)
      local items = {} --- @type snacks.picker.finder.Item[]
      for f, finder in ipairs(finders) do
        finder(function(item)
          if not opts.base then
            item.staged = opts.staged or f == 2
          end
          items[#items + 1] = item
        end)
      end
      table.sort(items, function(a, b)
        if a.file ~= b.file then
          return a.file < b.file
        end
        return a.pos[1] < b.pos[1]
      end)
      for _, item in ipairs(items) do
        cb(item)
      end
    end
  end

  --- Sources with no arc equivalent: say so instead of running git against a
  --- working copy it cannot read.
  --- @param name string
  --- @param reason string
  local function decline(name, reason)
    --- @type snacks.picker.finder
    Git[name] = function(opts, ctx)
      if not root_of(ctx) then
        return orig[name](opts, ctx)
      end
      unsupported(reason)
      return {}
    end
  end

  decline('files', '`arc ls-files` walks the whole repository (minutes). Use the regular file picker.')
  decline('grep', 'arc has no `grep`. Use the regular grep picker.')
  decline('branches', 'branch picker is not wired up for arc.')
  decline('stash', 'stash picker is not wired up for arc.')
end

local function patch_preview()
  local Preview = require('snacks.picker.preview')
  local orig_show, orig_diff = Preview.git_show, Preview.git_diff

  --- @param ctx snacks.picker.preview.ctx
  --- @return string?, boolean terminal
  local function context(ctx)
    local root = route.root(ctx.item.cwd or ctx.picker.opts.cwd or ctx.picker:cwd())
    return root, ctx.picker.opts.previewers.diff.style == 'terminal'
  end

  --- @param ctx snacks.picker.preview.ctx
  --- @return string[]
  local function pathspec(ctx)
    local spec = ctx.item.files or ctx.item.file
    return type(spec) == 'table' and spec or spec and { spec } or {}
  end

  --- @param ctx snacks.picker.preview.ctx
  function Preview.git_show(ctx)
    local root, terminal = context(ctx)
    if not root then
      return orig_show(ctx)
    end

    -- `arc show <commit>:<path>` prints file *contents*, not a diff, so it is
    -- not the counterpart of `git show <commit> -- <path>`. `arc log -p -n 1`
    -- is: same commit header, same patch, and it takes a path filter.
    local args = { 'log', '-p', '-n', '1' }
    if not terminal then
      args[#args + 1] = '--no-color'
    end
    args[#args + 1] = ctx.item.commit
    vim.list_extend(args, pathspec(ctx))

    Preview.cmd(argv(args), ctx, { ft = not terminal and 'git' or nil })
  end

  --- @param ctx snacks.picker.preview.ctx
  function Preview.git_diff(ctx)
    local root, terminal = context(ctx)
    if not root then
      return orig_diff(ctx)
    end

    local args = { 'diff', '--git' }
    if not terminal then
      args[#args + 1] = '--no-color'
    end

    local status = ctx.item.status
    if not status then
      args[#args + 1] = 'HEAD' -- generic diff against HEAD
    elseif status:find('[UAD][UAD]') then
      -- arc has no --cc; a plain diff is the best available view of a conflict.
    elseif status:sub(1, 1) ~= ' ' then
      args[#args + 1] = '--cached' -- staged changes
    end

    if ctx.item.file then
      args[#args + 1] = '--'
      args[#args + 1] = ctx.item.file
    end

    Preview.cmd(argv(args), ctx, { ft = not terminal and 'diff' or nil })
  end
end

local function patch_actions()
  local Util = require('snacks.picker.util')
  local translate = require('arcsnacks.translate')
  local orig_cmd = Util.cmd

  --- @param command string[]
  --- @param cb fun(lines: string[], code: number)
  --- @param opts? snacks.picker.util.cmd.Opts
  function Util.cmd(command, cb, opts)
    if command[1] == 'git' and opts and opts.cwd and route.root(opts.cwd) then
      local args, reason = translate.args(command)
      if not args then
        return unsupported(reason or 'unsupported git command')
      end
      command = argv(args)
    end
    return orig_cmd(command, cb, opts)
  end
end

function M.setup()
  if patched then
    return
  end
  patched = true

  patch_root()
  patch_sources()
  patch_preview()
  patch_actions()
end

return M
