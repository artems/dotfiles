--- Configuration for arcsigns.
---
--- @class ArcSigns.Config
--- @field arc_bin string
--- @field timeout_ms integer Default timeout for arc commands
--- @field mounts_ttl_ms integer How often ~/.arc/mount-points may be re-stat'ed
--- @field detect_local_repos boolean Walk up looking for .arc (for `arc init` repos)
--- @field current_line_blame boolean Allow gitsigns' current-line blame in arc buffers
--- @field blame ArcSigns.Config.Blame
--- @field stage ArcSigns.Config.Stage
---
--- @class ArcSigns.Config.Blame
--- @field enabled boolean
--- @field timeout_ms integer
--- @field slow_threshold_ms integer Whole-file blames slower than this are not repeated
---
--- @class ArcSigns.Config.Stage
--- @field verify boolean Read the index back after writing it

local M = {}

--- @type ArcSigns.Config
local defaults = {
  arc_bin = 'arc',
  timeout_ms = 10000,
  mounts_ttl_ms = 5000,
  detect_local_repos = true,
  current_line_blame = false,
  blame = {
    enabled = true,
    timeout_ms = 15000,
    slow_threshold_ms = 3000,
  },
  stage = {
    verify = true,
  },
}

--- @type ArcSigns.Config
local config = vim.deepcopy(defaults)

--- @param opts? table
function M.set(opts)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
end

--- @return ArcSigns.Config
function M.get()
  return config
end

return M
