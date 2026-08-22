--- Every `arc` invocation made on behalf of snacks goes through here.
---
--- Unlike arcsigns.cmd this does not use gitsigns' async machinery: snacks
--- drives everything from libuv callbacks, so a plain vim.system with a
--- completion callback is the right shape. Callbacks land in a fast-event
--- context — callers that touch the tree or the picker must vim.schedule.

local M = {}

--- @return ArcSigns.Config|{arc_bin: string, timeout_ms: integer}
local function config()
  local ok, cfg = pcall(require, 'arcsigns.config')
  if ok then
    return cfg.get()
  end
  return { arc_bin = 'arc', timeout_ms = 10000 }
end

--- @return string
function M.bin()
  return config().arc_bin
end

--- @class ArcSnacks.CmdOpts
--- @field cwd string
--- @field timeout? integer

--- @param args string[]
--- @param opts ArcSnacks.CmdOpts
--- @param on_done fun(ok: boolean, stdout: string, stderr: string)
--- @return vim.SystemObj? handle Live process, for callers that may lose interest
function M.run(args, opts, on_done)
  local cmd = { M.bin() }
  vim.list_extend(cmd, args)

  local ok, handle = pcall(vim.system, cmd, {
    cwd = opts.cwd,
    text = true,
    timeout = opts.timeout or config().timeout_ms,
    -- We pattern match on stderr in places; keep arc speaking English.
    env = { LC_ALL = 'C', LANGUAGE = 'C' },
  }, function(obj)
    on_done(obj.code == 0, obj.stdout or '', obj.stderr or '')
  end)

  if ok then
    return handle
  end

  do
    -- Spawn failure (ENOENT and friends): hand it back as a failed result
    -- rather than letting it escape into whichever callback we were called from.
    local reason = tostring(handle)
    local detect_ok, detect = pcall(require, 'arcsigns.detect')
    if detect_ok then
      detect.disable(('cannot run `%s`: %s'):format(M.bin(), reason))
    end
    vim.schedule(function()
      on_done(false, '', reason)
    end)
  end
end

--- Run an arc command with --json and decode the result.
--- @param args string[]
--- @param opts ArcSnacks.CmdOpts
--- @param on_done fun(decoded: any?, err: string?)
--- @return vim.SystemObj?
function M.json(args, opts, on_done)
  local a = vim.list_extend({}, args)
  a[#a + 1] = '--json'

  return M.run(a, opts, function(ok, stdout, stderr)
    if not ok then
      return on_done(nil, stderr ~= '' and vim.trim(stderr) or 'arc exited with an error')
    end
    local decoded_ok, decoded = pcall(vim.json.decode, stdout)
    if not decoded_ok then
      return on_done(nil, 'json decode: ' .. tostring(decoded))
    end
    on_done(decoded)
  end)
end

return M
