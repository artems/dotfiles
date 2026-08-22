--- Rewriting the small git command lines that picker actions build.
---
--- snacks.picker.actions never runs git through a helper — each action builds a
--- plain argv ({"git", "add", file}) and hands it to Snacks.picker.util.cmd.
--- Rewriting argv in that one chokepoint therefore covers git_stage,
--- git_restore, git_checkout and git_stash_apply at once, which beats forking
--- four actions that are mostly confirmation prompts and selection handling.
---
--- Only the verbs those actions actually emit are translated. Anything else
--- returns nil, and the caller reports it as unsupported rather than running a
--- half-understood command against a working copy.

local M = {}

--- @param argv string[] Full argv, starting with "git"
--- @return string[]? args arc arguments (without the binary), nil if unsupported
--- @return string? reason Why it is unsupported
function M.args(argv)
  local rest = { unpack(argv, 2) }
  local verb = rest[1]

  if verb == 'add' then
    -- `git add <files>` → same spelling in arc
    return rest
  elseif verb == 'restore' then
    if rest[2] == '--staged' then
      -- Unstage: arc spells `git restore --staged` as `arc reset`.
      local ret = { 'reset' }
      vim.list_extend(ret, { unpack(rest, 3) })
      return ret
    end
    -- Discard worktree changes.
    local ret = { 'checkout', '--' }
    vim.list_extend(ret, { unpack(rest, 2) })
    return ret
  elseif verb == 'checkout' then
    return rest
  elseif verb == 'stash' then
    return rest
  elseif verb == 'apply' then
    -- Hunk-level staging feeds a patch to `git apply`; arc has no such command.
    return nil, 'arc has no `apply`, so single hunks cannot be staged'
  end

  return nil, ('`git %s` has no arc equivalent'):format(verb or '?')
end

return M
