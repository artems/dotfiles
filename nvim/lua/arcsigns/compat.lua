--- The single place where arcsigns reaches into gitsigns' private modules.
---
--- Everything here is unversioned gitsigns internals; `:checkhealth arcsigns`
--- asserts that each symbol we rely on still exists.

local M = {}

local real_git ---@type table?

--- Load the real gitsigns/git.lua, bypassing our own package.preload entry.
--- @return table
function M.real_git()
  if real_git then
    return real_git
  end

  local name = 'gitsigns.git'
  local saved_preload, saved_loaded = package.preload[name], package.loaded[name]

  -- Drop the preload first, otherwise the nested require would recurse straight
  -- back into our router.
  package.preload[name], package.loaded[name] = nil, nil

  -- require (rather than loadfile) so vim.loader's bytecode cache and a
  -- non-standard package.path are both honoured.
  local ok, mod = pcall(require, name)

  package.preload[name], package.loaded[name] = saved_preload, saved_loaded

  if not ok then
    local path = vim.api.nvim_get_runtime_file('lua/gitsigns/git.lua', false)[1]
    assert(path, 'arcsigns: lua/gitsigns/git.lua not found on runtimepath')
    mod = assert(loadfile(path))(name)
  end

  real_git = mod
  return real_git
end

--- Load a gitsigns module, bypassing our package.preload entry for it.
---
--- Used by clb.lua, which preloads a patched 'gitsigns.current_line_blame'.
--- @param name string
--- @return table
function M.real_module(name)
  local saved_preload, saved_loaded = package.preload[name], package.loaded[name]
  package.preload[name], package.loaded[name] = nil, nil

  local ok, mod = pcall(require, name)

  package.preload[name] = saved_preload
  if not ok then
    package.loaded[name] = saved_loaded
    error(('arcsigns: failed to load %s: %s'):format(name, mod))
  end

  -- Keep the freshly loaded module in package.loaded: the caller patches it in
  -- place and returns it, so both paths must observe the same table.
  return mod
end

return M
