--- Every `arc` invocation goes through here.
---
--- Mirrors gitsigns/git/cmd.lua: async.wrap over gitsigns.system so the call
--- suspends the enclosing coroutine task instead of blocking, and the mandatory
--- async.schedule() afterwards moves us out of the fast-event context that
--- vim.system callbacks run in.

local async = require('gitsigns.async')
local log = require('gitsigns.debug.log')
local system = require('gitsigns.system').system

local config = require('arcsigns.config')
local detect = require('arcsigns.detect')

--- async.wrap defers the actual call into the task's resume step (async.lua:410),
--- so a spawn failure such as ENOENT would escape any pcall around the wrapped
--- function. Catch it here and hand it back as an ordinary failed result.
local asystem = async.wrap(3, function(cmd, opts, on_exit)
  local ok, err = pcall(system, cmd, opts, on_exit)
  if not ok then
    -- -1 marks a spawn failure; a real arc exit code is never negative.
    on_exit({ code = -1, signal = 0, stdout = '', stderr = tostring(err) })
  end
end)

--- @class ArcSigns.JobSpec : vim.SystemOpts
--- @field ignore_error? boolean

local M = {}

--- @async
--- @param args string[]
--- @param spec? ArcSigns.JobSpec
--- @return string[] stdout, string? stderr, integer code
function M.run(args, spec)
  spec = vim.deepcopy(spec or {}) --[[@as ArcSigns.JobSpec]]

  if spec.text == nil then
    spec.text = true
  end
  spec.timeout = spec.timeout or config.get().timeout_ms

  -- Force English messages: we pattern match on stderr.
  spec.env = vim.tbl_extend('force', spec.env or {}, {
    LC_ALL = 'C',
    LANGUAGE = 'C',
  })

  local bin = config.get().arc_bin
  local cmd = { bin }
  vim.list_extend(cmd, args)

  local obj = asystem(cmd, spec) --[[@as vim.SystemCompleted]]

  async.schedule()

  if obj.code == -1 then
    -- The binary could not be spawned at all. Give up on arc for this session
    -- rather than failing once per buffer.
    detect.disable(('cannot run `%s`: %s'):format(bin, obj.stderr or '?'))
    return {}, obj.stderr, obj.code
  end

  if not spec.ignore_error and obj.code > 0 then
    log.eprintf(
      "arcsigns: exit code %d from '%s':\n%s",
      obj.code,
      table.concat(cmd, ' '),
      obj.stderr
    )
  end

  local stdout = vim.split(obj.stdout or '', '\n')

  if spec.text and stdout[#stdout] == '' then
    -- Drop the empty string left behind by a trailing newline.
    stdout[#stdout] = nil
  end

  if log.verbose then
    log.vprintf('%d lines:', #stdout)
    for i = 1, math.min(10, #stdout) do
      log.vprintf('\t%s', stdout[i])
    end
  end

  if obj.stderr == '' then
    obj.stderr = nil
  end

  return stdout, obj.stderr, obj.code
end

--- @async
--- @param args string[]
--- @param spec? ArcSigns.JobSpec
--- @return any?, string? err
function M.json(args, spec)
  spec = vim.tbl_extend('force', spec or {}, { ignore_error = true })

  local args0 = vim.list_extend({}, args)
  args0[#args0 + 1] = '--json'

  local stdout, stderr, code = M.run(args0, spec)
  if code ~= 0 then
    return nil, stderr or ('exit code ' .. code)
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(stdout, '\n'))
  if not ok then
    return nil, 'json decode: ' .. tostring(decoded)
  end

  return decoded
end

return M
