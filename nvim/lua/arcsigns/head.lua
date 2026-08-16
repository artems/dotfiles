--- Reading arc repository metadata straight off disk, no subprocess.
---
--- gitsigns does the same for git (git/repo.lua:89-280) because the watcher
--- callback must be cheap: it fires on every index write.
---
---     .arc/HEAD             Symbolic: "trunk"     (or Id: "<sha>" when detached)
---     .arc/refs/heads/trunk Remote: "trunk"
---                           Id: "51d1394561...."
---     .arc/TREE             45e8ab6b0e....

local uv = vim.uv or vim.loop ---@diagnostic disable-line: deprecated

local M = {}

--- @param path string
--- @return string?
local function read_file(path)
  local stat = uv.fs_stat(path)
  if not stat or stat.type ~= 'file' then
    return nil
  end

  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

--- @param text string
--- @param key string
--- @return string?
local function field(text, key)
  return text:match(key .. ':%s*"(.-)"')
end

--- @class ArcSigns.Head
--- @field abbrev_head string Branch name, or short hash when detached, or '' if unborn
--- @field head_oid? string
--- @field head_ref? string Ref path relative to the arc dir, e.g. 'refs/heads/trunk'
--- @field detached boolean

--- Resolve HEAD for a working copy.
--- @param mount ArcSigns.Mount
--- @return ArcSigns.Head
function M.read(mount)
  -- Prefer the real on-disk store: the FUSE-backed <toplevel>/.arc is a
  -- different inode and reading it goes through the arc daemon.
  local base = mount.store or mount.arcdir

  local head = read_file(base .. '/HEAD')
  if not head then
    return { abbrev_head = '', detached = false }
  end

  local branch = field(head, 'Symbolic')
  if branch then
    local ref = 'refs/heads/' .. branch
    local ref_text = read_file(base .. '/' .. ref)
    return {
      abbrev_head = branch,
      head_oid = ref_text and field(ref_text, 'Id') or nil,
      head_ref = ref,
      detached = false,
    }
  end

  local oid = field(head, 'Id')
  if oid then
    return { abbrev_head = oid:sub(1, 7), head_oid = oid, detached = true }
  end

  return { abbrev_head = '', detached = false }
end

--- Hash of the tree HEAD points at. Changes on checkout/pull even when the
--- branch name does not, so the watcher uses it as an invalidation trigger.
--- @param mount ArcSigns.Mount
--- @return string?
function M.tree(mount)
  local text = read_file((mount.store or mount.arcdir) .. '/TREE')
  return text and vim.trim(text) or nil
end

return M
