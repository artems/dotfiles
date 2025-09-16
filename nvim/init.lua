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
vim.opt.showbreak = "↪ "                        -- Show "↪ " at the beginning of wrapped lines
vim.opt.breakindent = true                      -- Visually indent each wrapped line with the same amount of space as the beginning of that line

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
vim.opt.gdefault = false                        -- Turn off global substitution by default
vim.opt.incsearch = true                        -- Search the pattern while typing
vim.opt.smartcase = false                       -- Turn off ignoring case in search patterns
vim.opt.ignorecase = false                      -- Turn off ignoring case in search patterns

-- Appearance
vim.opt.title = true                            -- Set the terminal title
vim.opt.number = true                           -- Show the line number in front of each line
vim.opt.showcmd = true                          -- Show (partial) command in the last line of the screen
vim.opt.showmode = false                        -- Hide the current mode on the last line
vim.opt.mousehide = true                        -- Hide the mouse pointer when typing text
vim.opt.showmatch = false                       -- Don't jump to the matching bracket in insert mode
vim.opt.visualbell = true                       -- Use a visual bell instead of beeping
vim.opt.cursorline = false                      -- Don't highlight the screen line of the cursor

vim.opt.list = true                             -- Display unprintable characters
vim.opt.listchars = {}                          -- Strings to use in "list" mode:
vim.opt.listchars:append({ tab = "▸ " })        --   Characters to show for a tab
vim.opt.listchars:append({ nbsp = "␣" })        --   Character to show for a non-breakable space
vim.opt.listchars:append({ trail = "⋅" })       --   Character to show for trailing spaces
vim.opt.listchars:append({ extends = "❯" })     --   Character to show in the last column
vim.opt.listchars:append({ precedes = "❮" })    --   Character to show in the first visible column of the physical line

vim.opt.display = {}                            -- Display settings:
vim.opt.display:append("uhex")                  --   Show unprintable characters in hexadecimal as <xx>
vim.opt.display:append("truncate")              --   Show "@@@" in the last screen line if the rest of the line

vim.opt.signcolumn = "yes"                      -- Display signs
vim.opt.laststatus = 3                          -- Always display a global statusline
vim.opt.showtabline = 1                         -- Show tabs only if there are at least two tab pages

vim.opt.foldtext = ""                           -- Display folded line with syntax highlighting

-- Colors
vim.opt.background = "dark"                     -- Set background to dark
vim.cmd("colorscheme retrobox")                 -- Apply the retrobox colorscheme

-- Windows
vim.opt.splitright = true                       -- Put the new window right of the current one
vim.opt.splitbelow = true                       -- Put the new window below the current one
vim.opt.scrolljump = 1                          -- Minimal number of lines to scroll when the cursor gets off the screen
vim.opt.scrolloff = 0                           -- Minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 5                       -- Minimal number of columns to keep on the right and left of the edge of the screen
vim.opt.smoothscroll = true                     -- Allow for partial scrolling of a wrapped line

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
vim.opt.completeopt:append("popup")             --   Show additional information in a popup window
vim.opt.completeopt:append("menuone")           --   Use a popup menu even when there is only one match
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

vim.opt.isfname:append("@-@")                   -- Take "@" symbol into account when extracting filename

vim.opt.ttimeout = true                         -- Timeout for key codes
vim.opt.ttimeoutlen = 50                        -- Wait up to 50ms after <Esc> for special key

-- Spell checking
vim.opt.spell = false                           -- Disable spell checking by default
vim.opt.spelllang = { "en", "ru" }              -- A list of word list names

-- Performance
vim.opt.synmaxcol = 1000                        -- Maximal column in which to search for syntax items
vim.opt.updatetime = 300                        -- Emit 'CursorHold' event after 300ms

-- ===========================================================================
-- ! Key mappings
vim.keymap.set("n", "Q", "<Nop>")

-- Move lines up and down
vim.keymap.set("n", "<C-j>", ":move .+1<CR>==", { noremap = true })
vim.keymap.set("n", "<C-k>", ":move .-2<CR>==", { noremap = true })
vim.keymap.set("x", "<C-j>", ":move '>+1<CR>gv=gv", { noremap = true })
vim.keymap.set("x", "<C-k>", ":move '<-2<CR>gv=gv", { noremap = true })

-- ===========================================================================
-- ! Misc
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep"
elseif vim.fn.executable("ag") == 1 then
  vim.opt.grepprg = "ag --vimgrep"
elseif vim.fn.executable("grep") == 1 then
  vim.opt.grepprg = "grep -n"
end

vim.api.nvim_create_augroup("vimrc_highlight_on_yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = "vimrc_highlight_on_yank",
  callback = function()
    (vim.hl or vim.highlight).on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.api.nvim_create_augroup("vimrc_daily_colorscheme", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = "vimrc_daily_colorscheme",
  callback = function()
    vim.schedule(function()
      local allowed_colorschemes = {
        "kanagawa",
        "catppuccin",
        "tokyonight",
      }

      local yearday = os.date("*t").yday or 0
      local colorscheme_index = (yearday % #allowed_colorschemes) + 1
      local selected_scheme = allowed_colorschemes[colorscheme_index]

      vim.cmd("colorscheme " .. selected_scheme)
    end)
  end
})

-- ===========================================================================
-- ! Bootstrap lazy.nvim -----------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--branch=stable",
    "--filter=blob:none",
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
      "catppuccin/nvim",
      priority = 1000,
      name = "catppuccin",
      opts = { flavour = "mocha" },
    },
    {
      "folke/tokyonight.nvim",
      priority = 1000,
      opts = { style = "night" },
    },
    {
      "rebelot/kanagawa.nvim",
      priority = 1000,
      opts = {
        colors = {
          theme = { all = { ui = { bg_gutter = "none" } } }
        }
      },
    },
    -- * Languages tools
    {
      "neovim/nvim-lspconfig",
      version = "v2.4.x",
      config = function() require("plugins.lspconfig") end,
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      branch = "main",
      config = function() require("plugins.treesitter") end,
    },
    -- * Navigation
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = require('plugins.snacks-opts'),
      init = function() require('plugins.snacks-init') end,
      keys = {
        { "-", function() require('snacks').explorer() end, desc = "File Explorer" },
        { "]]", function() require('snacks').words.jump(vim.v.count1) end, desc = "Next Reference" },
        { "[[", function() require('snacks').words.jump(-vim.v.count1) end, desc = "Prev Reference" },
        { "<C-p>", function() require('snacks').picker.files() end, desc = "Find Files" },
        { "<C-n>", function() require('snacks').picker.recent() end, desc = "Recent" },
        { "<C-h>", function() require('snacks').picker.buffers() end, desc = "Buffers" },
        { "<leader>g", function() require('snacks').picker.grep() end, desc = "Grep" },
        { "<leader><leader>", function() require('snacks').terminal() end, desc = "Toggle Terminal", mode = { "n", "t" } },
      },
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
    },
    -- * Editing enhancements
    {
      "AndrewRadev/splitjoin.vim",
      config = function()
        vim.g.splitjoin_trailing_comma = true
        vim.g.splitjoin_html_attributes_bracket_on_new_line = true
      end
    },
    {
      "kylechui/nvim-surround",
      version = "^3.0.0",
      event = "VeryLazy",
      opts = {
        move_cursor = "sticky"
      },
    },
    {
      "saghen/blink.cmp",
      version = "1.*",
      config = function() require("plugins.blinkcmp") end,
      event = "VeryLazy",
    },
    -- * Editing UI/UX
    {
      "j-hui/fidget.nvim",
      opts = {},
    },
    {
      "folke/todo-comments.nvim",
      opts = {},
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    {
      "lewis6991/satellite.nvim",
      commit = "1febb774fed40f923a9955e0d029601bd4cabc42",
      opts = {},
    },
    {
      "SmiteshP/nvim-navic",
      config = function() require("plugins.navic") end,
      dependencies = {
        "neovim/nvim-lspconfig",
        "nvim-tree/nvim-web-devicons",
      },
    },
    {
      "nvim-lualine/lualine.nvim",
      config = function() require("plugins.lualine") end,
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
    },
    {
      "catgoose/nvim-colorizer.lua",
      opts = {
        filetypes = { "css", "html" },
        user_default_options = {
          css = true,
          names = false,
          virtualtext_inline = true,
        },
      },
    },
    -- * VCS
    {
      "lewis6991/gitsigns.nvim",
      config = function() require("plugins.gitsigns") end,
    },
    -- * AI
    {
      "olimorris/codecompanion.nvim",
      cmd = {
        "CodeCompanion",
        "CodeCompanionCmd",
        "CodeCompanionChat",
        "CodeCompanionActions",
      },
      config = function() require("plugins.codecompanion") end,
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
    },
  },
})
