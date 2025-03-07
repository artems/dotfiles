-- ===========================================================================
-- ! General preferences -----------------------------------------------------
vim.opt.mouse = ""                              -- Disable mouse in all modes
vim.opt.encoding = "utf-8"                      -- Set character encoding used inside Neovim

-- ! Edit options ------------------------------------------------------------
vim.opt.smarttab = true                         -- Use "shiftwidth" for <Tab> in front of a line instead of "softtabstop"
vim.opt.expandtab = true                        -- Use spaces to insert a <Tab>
vim.opt.autoindent = true                       -- Copy indent from current line when starting a new line
vim.opt.smartindent = true                      -- Indent after "{" character or keywords
vim.opt.tabstop = 4                             -- Number of spaces that a <Tab> in the file counts for
vim.opt.shiftwidth = 4                          -- Number of spaces to use for each step of autoindent
vim.opt.softtabstop = 4                         -- Number of spaces to use for <Tab> hit

vim.opt.wrap = true                             -- Wrap long lines
vim.opt.linebreak = true                        -- Don't break words
vim.opt.breakindent = true                      -- Visually indent each wrapped line with the same amount of space as the beginning of that line
vim.opt.showbreak = "↪ "                        -- Show "↪ " at the beginning of wrapped lines

vim.opt.list = true                             -- Display unprintable characters
vim.opt.listchars = {}                          -- Strings to use in "list" mode:
vim.opt.listchars:append({ tab = "▸ " })        --   Characters to show for a tab
vim.opt.listchars:append({ nbsp = "×" })        --   Character to show for a non-breakable space
vim.opt.listchars:append({ trail = "·" })       --   Character to show for trailing spaces
vim.opt.listchars:append({ extends = "❯" })     --   Character to show in the last column
vim.opt.listchars:append({ precedes = "❮" })    --   Character to show in the first visible column of the physical line

vim.opt.display = {}                            -- Display settings:
vim.opt.display:append("uhex")                  --   Show unprintable characters in hexadecimal as <xx>
vim.opt.display:append("truncate")              --   Show "@@@" in the last screen line if the rest of the lin

-- Formatting
vim.opt.textwidth = 78                          -- Maximum width of text when formatting

local formatoptions = ""                        -- Automatic formatting settings:
formatoptions = formatoptions .. "j"            --   Remove a comment leader when joining lines
formatoptions = formatoptions .. "c"            --   Auto-wrap comments using textwidth
formatoptions = formatoptions .. "r"            --   Automatically insert the current comment leader after hitting <Enter>
formatoptions = formatoptions .. "o"            --   Automatically insert the current comment leader after hitting "o"
formatoptions = formatoptions .. "q"            --   Allow formatting of comments with "gq"
formatoptions = formatoptions .. "l"            --   Long lines are not broken in insert mode
formatoptions = formatoptions .. "n"            --   Recognize numbered lists
vim.opt.formatoptions = formatoptions

-- Search
vim.opt.hlsearch = true                         -- Highlight all found matches
vim.opt.incsearch = true                        -- Search the pattern while typing
vim.opt.gdefault = false                        -- Turn off global substitution by default
vim.opt.ignorecase = false                      -- Turn off ignoring case in search patterns by default
vim.opt.smartcase = false                       -- Always turn off ignoring case in search patterns
vim.cmd("nohlsearch")                           -- Turn off current highlight when reloading '.vimrc'

-- Appearance
vim.opt.title = true                            -- Set the terminal title
vim.opt.number = true                           -- Show the line number in front of each line
vim.opt.showcmd = true                          -- Show (partial) command in the last line of the screen
vim.opt.showmode = false                        -- Hide the current mode on the last line
vim.opt.mousehide = true                        -- Hide the mouse pointer when typing text
vim.opt.showmatch = false                       -- Don't jump to the matching bracket in insert mode
vim.opt.visualbell = true                       -- Use a visual bell instead of beeping
vim.opt.cursorline = false                      -- Don't highlight the screen line of the cursor

vim.opt.signcolumn = "number"                   -- Display signs in the "number" column.
vim.opt.laststatus = 2                          -- Always display a statusline
vim.opt.showtabline = 1                         -- Show tabs only if there are at least two tab pages

-- Colors
vim.opt.background = "dark"                     -- Set background to dark
vim.cmd("colorscheme retrobox")                 -- Apply the retrobox colorscheme

-- Windows
vim.opt.splitright = true                       -- Put the new window right of the current one
vim.opt.splitbelow = true                       -- Put the new window below the current one
vim.opt.scrolljump = 1                          -- Minimal number of lines to scroll when the cursor gets off the screen
vim.opt.scrolloff = 0                           -- Minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 5                       -- Minimal number of columns to keep on the right and left of the edge of the screen

-- Diff options
vim.opt.diffopt = {}                            -- Settings for diff mode:
vim.opt.diffopt:append("filler")                --   Show filler lines
vim.opt.diffopt:append("iwhite")                --   Ignore changes in the amount of white space
vim.opt.diffopt:append("vertical")              --   Start diff mode with vertical splits
vim.opt.diffopt:append("closeoff")              --   Execute ':diffoff' if there is only one window remaining with 'diff' set
vim.opt.diffopt:append("internal")              --   Use the internal diff library
vim.opt.diffopt:append("algorithm:patience")    --   Use the patience algorithm for diff

-- Wildmenu and completion
vim.opt.wildmenu = true                         -- Enhance command-line completion
vim.opt.wildmode = "list:longest"               -- List all matches and complete till the longest common string
vim.opt.wildignore = {}                         -- A list of patterns to be ignored when expanding wildcards:
vim.opt.wildignore:append(".hg")                --   Ignore mercurial version control directories
vim.opt.wildignore:append(".git")               --   Ignore git version control directories
vim.opt.wildignore:append(".svn")               --   Ignore subversion version control directories
vim.opt.wildignore:append(".DS_Store")          --   Ignore macOS 'Desktop Services Store'

vim.opt.completeopt = {}                        -- A list of options for Insert mode completion:
vim.opt.completeopt:append("menuone")           --   Use a popup menu even when there is only one match
vim.opt.completeopt:append("preview")           --   Show additional information in a preview window
vim.opt.completeopt:append("noinsert")          --   Do not insert any text for a match
vim.opt.completeopt:append("noselect")          --   Do not select a match in the menu

-- Environment
vim.opt.backup = false                          -- Disable backups
vim.opt.swapfile = false                        -- Disable swap files
vim.opt.undofile = true                         -- Enable persistent undo

vim.opt.hidden = true                           -- Allow editing several buffers at the same time
vim.opt.history = 1000                          -- Number of entries about last ":" commands or search patterns
vim.opt.undolevels = 1000                       -- Maximum number of changes that can be undone
vim.opt.undoreload = 10000                      -- Save the whole buffer for undo when reloading it

vim.opt.isfname:append("@-@")                   -- Take "@" symbol into account when extracting filenames

vim.opt.ttimeout = true                         -- Timeout for key codes
vim.opt.ttimeoutlen = 100                       -- Wait up to 100ms after <Esc> for special key

-- Spell checking
vim.opt.spell = false                           -- Disable spell checking by default
vim.opt.spelllang = { "en", "ru" }              -- A list of word list names

-- Performance
vim.opt.synmaxcol = 3000                        -- Maximal column in which to search for syntax items
vim.opt.updatetime = 2000                       -- Emit 'CursorHold' event after 2000ms

-- ===========================================================================
-- ! Key mappings
vim.keymap.set("n", "Q", "<Nop>", { noremap = true })

-- Move lines up and down
vim.keymap.set("n", "<C-j>", ":move .+1<CR>==", { noremap = true })
vim.keymap.set("n", "<C-k>", ":move .-2<CR>==", { noremap = true })
vim.keymap.set("x", "<C-j>", ":move '>+1<CR>gv=gv", { noremap = true })
vim.keymap.set("x", "<C-k>", ":move '<-2<CR>gv=gv", { noremap = true })

-- Use 'jk' to exit insert mode
vim.keymap.set("i", "jk", "<Esc>", { noremap = true })

-- Reload Neovim config
vim.keymap.set("n", "<leader>re", ":source $MYVIMRC<CR>", { noremap = true })

-- ===========================================================================
-- Options for 'netrw' -------------------------------------------------------
vim.g.netrw_hide = 1                              -- Hide files that match the specified patterns
vim.g.netrw_banner = false                        -- Hide the banner at the top of the Netrw window
vim.g.netrw_altfile = true                        -- Preserve the alternate file when opening files in Netrw
vim.g.netrw_list_hide = "^\\.\\./$,^\\./$"        -- Hide (../) and (./) entries in Netrw

vim.keymap.set("n", "-", function()
  local filename = vim.fn.expand("%:t")
  vim.cmd("Explore")
  vim.fn.search('\\<' .. vim.fn.escape(filename, '\\') .. '\\>')
end, { noremap = true, silent = true })

-- Options for 'bufexplorer' -------------------------------------------------
vim.g.bufExplorerSortBy = "mru"                   -- Sort buffers by most recently used
vim.g.bufExplorerFindActive = true                -- Automatically find the active buffer
vim.g.bufExplorerShowTabBuffer = false            -- Do not show buffers from other tabs
vim.g.bufExplorerShowDirectories = false          -- Do not show directories
vim.g.bufExplorerShowRelativePath = true          -- Show relative paths
vim.g.bufExplorerSplitOutPathName = false         -- Do not split the filename and path
vim.g.bufExplorerDisableDefaultKeyMapping = true  -- Disable default key mappings

vim.api.nvim_create_augroup("vimrc_plugin_bufexplorer_setup", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "vimrc_plugin_bufexplorer_setup",
  pattern = "bufexplorer",
  callback = function()
    vim.api.nvim_buf_set_keymap(0, "n", "?", "<F1>", { silent = true })
    vim.api.nvim_buf_set_keymap(0, "n", "<Space>", "o", { silent = true })
  end,
})

-- ===========================================================================
-- ! Misc
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep"
elseif vim.fn.executable("ag") == 1 then
  vim.opt.grepprg = "ag --vimgrep"
elseif vim.fn.executable("grep") == 1 then
  vim.opt.grepprg = "grep -n"
end

vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ===========================================================================
-- ! Bootstrap lazy.nvim -----------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out .. "\n\n", "WarningMsg" },
      { "Press any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- ! Setup lazy.nvim ---------------------------------------------------------
require("lazy").setup({
  spec = {
    -- * Colorschemes
    {
      "ellisonleao/gruvbox.nvim",
      priority = 1000,
      opts = { contrast = "hard" },
      init = function() vim.cmd("colorscheme gruvbox") end
    },
    {
      "catppuccin/nvim",
      lazy = true,
      name = "catppuccin",
      opts = { flavour = "mocha" },
    },
    {
      "folke/tokyonight.nvim",
      lazy = true,
      opts = { style = "night" },
    },
    -- * Languages tools
    {
      'neovim/nvim-lspconfig',
      tag = "v1.7.0",
      config = function() require("lazy.plugins.lspconfig") end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      tag = "v0.9.3",
      build = ":TSUpdate",
      config = function() require("lazy.plugins.treesitter") end,
    },
    -- * Navigation
    {
      "jlanzarotta/bufexplorer",
      tag = "7.8.0",
      keys = { {"<Space>", "<CMD>BufExplorer<CR>"} }
    },
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.8",
      opts = function() return require("lazy.plugins.telescope") end,
      keys = {
        { "<C-n>", "<CMD>Telescope oldfiles<CR>" },
        { "<C-s>", "<CMD>Telescope live_grep<CR>" },
        { "<C-p>", "<CMD>Telescope find_files<CR>" },
      },
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    -- * Editing enhancements
    { "tpope/vim-surround" },
    { "tpope/vim-unimpaired" },
    {
        "AndrewRadev/splitjoin.vim",
        init = function()
            vim.g.splitjoin_join_mapping = "gJ"
            vim.g.splitjoin_split_mapping = "gS"
        end,
    },
    -- * Editing UI/UX
    { 'j-hui/fidget.nvim', tag = "v1.6.1", opts = {} },
    { "karb94/neoscroll.nvim", opts = { easing = 'sine' } },
    {
      'nvim-lualine/lualine.nvim',
      opts = {
        sections = {
          lualine_x = { 'encoding', { 'filetype', colored = false } },
        },
        tabline = {
          lualine_a = { { 'tabs', mode = 1, show_modified_status = false } },
        }
      },
      dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    { "nvim-treesitter/nvim-treesitter-context", opts = true },
    -- * AI
    {
      "olimorris/codecompanion.nvim",
      config = function() require("lazy.plugins.codecompanion") end,
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
    },
    -- * VCS
    -- fugitive
    -- gitgutter
  },
})
