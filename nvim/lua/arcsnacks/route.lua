--- Which backend owns a path.
---
--- arcsigns.detect already answers this cheaply — a prefix match against
--- ~/.arc/mount-points behind a full-path cache, negative entries included — so
--- we borrow it instead of growing a second detector. Everything it does not
--- claim stays git, which is what lets a git repo and an arc working copy be
--- open in the same session: the question is asked per path, per call, and
--- never cached into a session-wide verdict.

local M = {}

--- Normalize the way Snacks.git.get_root does, so buffer numbers and empty
--- names resolve identically on both sides of the patch.
--- @param path? string|integer Path, buffer number, or nil for the current buffer
--- @return string?
function M.normalize(path)
  path = path or 0
  if type(path) == 'number' then
    if not vim.api.nvim_buf_is_valid(path) then
      return nil
    end
    path = vim.api.nvim_buf_get_name(path)
  end
  if path == '' then
    path = (vim.uv or vim.loop).cwd() --- @diagnostic disable-line: deprecated
  end
  if type(path) ~= 'string' or path == '' then
    return nil
  end
  return vim.fs.normalize(path)
end

--- @param path? string|integer
--- @return ArcSigns.Mount?
function M.mount(path)
  local ok, detect = pcall(require, 'arcsigns.detect')
  if not ok then
    return nil
  end

  path = M.normalize(path)
  if not path then
    return nil
  end

  return detect.workspace(path)
end

--- Working copy root for a path, or nil when this is not arc.
--- @param path? string|integer
--- @return string?
function M.root(path)
  local mount = M.mount(path)
  return mount and mount.toplevel or nil
end

--- Path relative to its working copy root.
--- @param path string
--- @param root string
--- @return string
function M.relative(path, root)
  path = vim.fs.normalize(path)
  if path == root then
    return '.'
  elseif vim.startswith(path, root .. '/') then
    return path:sub(#root + 2)
  end
  return path
end

return M
