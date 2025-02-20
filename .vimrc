set nocompatible                    " use Vim improvements

" ============================================================================
" ! Package setup

" Colorschemes
packadd! gruvbox

" Search
packadd! ack
packadd! fzf
packadd! fzf_vim

" Languages tools
packadd! ale

" Files/Buffers
packadd! vinegar
packadd! bufexplorer

" Editing enhancements
packadd! abolish
packadd! commentary
packadd! editorconfig
packadd! jsbeautify
packadd! matchit
packadd! repeat
packadd! splitjoin
packadd! surround
packadd! unimpaired

" Editing UI/UX
packadd! csscolor
packadd! highlightedyank
packadd! lightline
packadd! lightline_ale
packadd! smoothie
packadd! traces

" VCS
packadd! fugitive
packadd! gitgutter

" Filetype plugins
packadd! javascript_new_jsx

" ============================================================================
" ! General preferences
syntax enable                       " turn on syntax highlighting
filetype plugin on                  " load built-in filetype plugins
filetype indent on                  " load built-in filetype indents

set encoding=utf-8                  " character encoding used inside vim.
set fileencodings=utf-8,default     " list of character encodings used for auto detection

" Edit
set smarttab                        " use 'shiftwidth' for <Tab> in front of a line instead of 'softtabstop'
set expandtab                       " use spaces to insert a <Tab>
set autoindent                      " copy indent from current line when starting a new line
set smartindent                     " indent after '{' character or keywords
set tabstop=4                       " number of spaces that a <Tab> in the file counts for
set shiftwidth=4                    " number of spaces to use for each step of autoindent
set softtabstop=4                   " number of spaces to use for <Tab> hit
set backspace=indent,eol,start      " allow backspacing over all
set nrformats-=octal                " don't recognize octal numbers for Ctrl-A and Ctrl-X

set wrap                            " wrap long lines
set linebreak                       " don't break words
set showbreak=↪\                    " show '↪ ' at the beginning of wrapped lines
set breakindent                     " visually indent each wrapped line with the same amount of space as the beginning of that line

set list                            " display unprintable characters
set listchars=                      " strings to use in 'list' mode:
set listchars+=tab:▸\               "   characters to show for a tab
set listchars+=trail:·              "   character to show for trailing spaces
set listchars+=extends:❯            "   character to show in the last column
set listchars+=precedes:❮           "   character to show in the first visible column of the physical line
set listchars+=nbsp:×               "   character to show for a non-breakable space

set fillchars+=vert:\|              " set "\|" as character to fill vertical separators

set display=
set display+=uhex                   " show unprintable characters hexadecimal as <xx>
set display+=truncate               " show '@@@' in the last screen line if rest of the line is not displayed

" Formatting
set textwidth=80                    " maximum width of text when formatting
set formatoptions=                  " disable wrapping text in Insert mode
set formatoptions+=c                "   c - auto-wrap comments using textwidth
set formatoptions+=r                "   r - automaticly insert the current comment leader after hitting <Enter>
set formatoptions+=o                "   o - automaticly insert the current comment leader after hitting 'o'
set formatoptions+=l                "   l - long lines are not broken in insert mode
set formatoptions+=q                "   q - allow formatting of comments with 'gq'
set formatoptions+=j                "   j - remove a comment leader when joining lines

" Search
set hlsearch                        " highlight all found matches
set incsearch                       " search the pattern while typing
set nogdefault                      " turn off global substitution by default
set noignorecase                    " turn off ignoring case in search patterns by default
set nosmartcase                     " turn off ignoring case in search patterns
nohlsearch                          " turn off current highlight when reloading '.vimrc'

" Appearance
set title                           " set the terminal title
set number                          " show the line number in front of each line
set showcmd                         " show (partial) command in the last line of the screen
set showmode                        " show the current mode on the last line
set mousehide                       " hide the mouse pointer when typing a text
set visualbell                      " use a visual bell instead of beeping
set noshowmatch                     " don't jump to the matching bracket in insert mode
set nocursorline                    " don't highlight the screen line of the cursor
set signcolumn=number               " always display sign column
set showtabline=1                   " show tabs only if there are at least two tab pages
set shortmess=tTI                   " truncate messages on command line, turn off intro when staring Vim
set laststatus=2                    " always display a statusline

" Colors
set background=dark
let g:gruvbox_number_column='bg1'
let g:gruvbox_guisp_fallback='bg'
let g:gruvbox_invert_selection=0
colorscheme gruvbox

" use 24-bit color whenever possible
if has('termguicolors') && $COLORTERM ==# 'truecolor'
    if (&term =~# '^tmux')
        let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
    endif

    set termguicolors               " use gui colors in the terminal
endif

" Window
set splitright                      " put the new window right the current one
set splitbelow                      " put the new window below the current one
set scrolloff=0                     " minimal number of screen lines to keep above and below the cursor
set scrolljump=1                    " minimal number of lines to scroll when the cursor gets off the screen
set sidescrolloff=5                 " minimal number of columns to keep on the right and left of edge of the screen

set diffopt=                        " settings for diff mode:
set diffopt+=filler                 "   show filler lines
set diffopt+=iblank                 "   ignore changes where lines are all blank
set diffopt+=iwhite                 "   ignore changes in amount of white space
set diffopt+=vertical               "   start diff mode with vertical splits
set diffopt+=closeoff               "   execute ':diffoff' if there is only one window remaining with 'diff' set
set diffopt+=internal               "   use the internal diff library
set diffopt+=algorithm:patience     "   ?

set wildmenu                        " enhance command-line completion
set wildmode=list:longest           " list all matches and complete till longest common string
set wildignore=                     " a list of patterns to be ignored when expanding wildcards:
set wildignore+=.hg,.git,.svn       "   ignore version control directories
set wildignore+=.DS_Store           "   ignore macOS 'Desktop Services Store'
set wildcharm=<C-Z>                 " ?

set completeopt=                    " a list of options for Insert mode completion:
set completeopt+=menuone            "   use a popup menu also when there is only one match
set completeopt+=noinsert           "   do not insert any text for a match
set completeopt+=noselect           "   do not select a match in the menu
set completeopt+=popup              "   show extra information in a popup window

" Environment
set undofile                        " enable persistent undo
set undodir=~/.vimtmp/undo//        " folder for undo files
set nobackup                        " disable backups
set backupdir=~/.vimtmp/backup//    " directory for backups
set noswapfile                      " disable swap files
set directory=~/.vimtmp/backup//    " directory for swap files

set hidden                          " allow to edit several buffers at the same time
set history=1000                    " number of entries about last ":" commands or search patterns
set undolevels=1000                 " maximum number of changes that can be undone
set undoreload=10000                " save the whole buffer for undo when reloading it when the number of lines is smaller then the value of this option

set ttimeout                        " timeout for key codes
set ttimeoutlen=100                 " wait up to 100ms after <Esc> for special key

" Spell checking
set nospell                         " disable spell checking by default
set spelllang=en,ru                 " a list of word list names
set spelloptions=camel              " take CamelCase into account

" Performance
set synmaxcol=2000                  " maximal column in which to search for syntax items
set updatetime=200                  " emit 'CursorHold' event after 200ms

" ============================================================================
" ! Key mappings
nnoremap Y      y$
nnoremap Q      <Nop>
inoremap jk     <Esc>
inoremap <C-U>  <C-G>u<C-U>
inoremap <C-W>  <C-G>u<C-W>

" Use <C-L> to clear the highlighting of hlsearch.
nnoremap <silent> <C-L> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>

" Move lines up and down
nnoremap <C-j>  :move .+1<CR>==
nnoremap <C-k>  :move .-2<CR>==
xnoremap <C-j>  :move '>+1<CR>gv=gv
xnoremap <C-k>  :move '<-2<CR>gv=gv

" reload '.vimrc'
nnoremap <leader>re :source $MYVIMRC<CR>

" ============================================================================
" ! FileType autocommands
augroup vimrc_filetype_vim_setup
    autocmd!
    autocmd FileType vim set foldenable foldmethod=marker
augroup end

" ============================================================================
" Options for 'netrw' --------------------------------------------------------
let g:netrw_altfile=1

" Options for 'minpac' -------------------------------------------------------
function! PackInit() abort
    packadd minpac

    call minpac#init()

    call minpac#add('k-takata/minpac', { 'type': 'opt', 'name': 'minpac' })

    " Colorschemes
    call minpac#add('lifepillar/vim-gruvbox8', { 'type': 'opt', 'name': 'gruvbox' })

    " Search
    call minpac#add('mileszs/ack.vim', { 'type': 'opt', 'name': 'ack' })
    call minpac#add('junegunn/fzf', { 'type': 'opt', 'name': 'fzf' })
    call minpac#add('junegunn/fzf.vim', { 'type': 'opt', 'name': 'fzf_vim' })

    " Language tools
    call minpac#add('dense-analysis/ale', { 'type': 'opt', 'name': 'ale' })

    " Files/Buffers
    call minpac#add('tpope/vim-vinegar', { 'type': 'opt', 'name': 'vinegar' })
    call minpac#add('jlanzarotta/bufexplorer',
                \ { 'type': 'opt', 'name': 'bufexplorer' })

    " Editing enhancements
    call minpac#add('tpope/vim-abolish', { 'type': 'opt', 'name': 'abolish' })
    call minpac#add('tpope/vim-commentary',
                \ { 'type': 'opt', 'name': 'commentary' })
    call minpac#add('editorconfig/editorconfig-vim',
                \ { 'type': 'opt', 'name': 'editorconfig' })
    call minpac#add('maksimr/vim-jsbeautify',
                \ { 'type': 'opt', 'name': 'jsbeautify' })
    call minpac#add('tpope/vim-repeat', { 'type': 'opt', 'name': 'repeat' })
    call minpac#add('AndrewRadev/splitjoin.vim', 
                \ { 'type': 'opt', 'name': 'splitjoin' })
    call minpac#add('tpope/vim-surround',
                \ { 'type': 'opt', 'name': 'surround' })
    call minpac#add('tpope/vim-unimpaired',
                \ { 'type': 'opt', 'name': 'unimpaired' })

    " UI/UX
    call minpac#add('ap/vim-css-color',
                \ { 'type': 'opt', 'name': 'csscolor' })
    call minpac#add('machakann/vim-highlightedyank',
                \ { 'type': 'opt', 'name': 'highlightedyank' })
    call minpac#add('itchyny/lightline.vim',
                \ { 'type': 'opt', 'name': 'lightline' })
    call minpac#add('maximbaz/lightline-ale',
                \ { 'type': 'opt', 'name': 'lightline_ale' })
    call minpac#add('psliwka/vim-smoothie',
                \ { 'type': 'opt', 'name': 'smoothie' })
    call minpac#add('markonm/traces.vim', { 'type': 'opt', 'name': 'traces' })

    " VCS
    call minpac#add('tpope/vim-fugitive',
                \ { 'type': 'opt', 'name': 'fugitive' })
    call minpac#add('airblade/vim-gitgutter',
                \ { 'type': 'opt', 'name': 'gitgutter' })

    " Filetype plugins
    call minpac#add('HerringtonDarkholme/yats.vim',
                \ { 'type': 'opt', 'name': 'javascript_new_jsx' })
endfunction

command! PackClean  source $MYVIMRC | call PackInit() | call minpac#clean()
command! PackUpdate source $MYVIMRC | call PackInit() | call minpac#update()
command! PackStatus source $MYVIMRC | call PackInit() | call minpac#status()

" Options for 'ack' ----------------------------------------------------------
let g:ackhighlight=1                " highlight the searched term

" Options for 'fzf.vim' ------------------------------------------------------
let g:fzf_buffers_jump=1            " jump to the existing window if possible
let g:fzf_command_prefix='Fzf'

nnoremap <C-P>      :FzfFiles!<CR>
nnoremap <C-N>      :FzfHistory!<CR>

" Options for 'bufexplorer' --------------------------------------------------
let g:bufExplorerSortBy='mru'
let g:bufExplorerFindActive=1
let g:bufExplorerShowTabBuffer=0
let g:bufExplorerShowDirectories=0
let g:bufExplorerShowRelativePath=1
let g:bufExplorerSplitOutPathName=0
let g:bufExplorerDisableDefaultKeyMapping=1

nnoremap <Space>    :BufExplorer<CR>

augroup vimrc_plugin_bufexplorer_setup
    autocmd!
    autocmd FileType bufexplorer nmap <silent> <buffer> ? <F1>
    autocmd FileType bufexplorer nmap <silent> <buffer> <Space> q
augroup end

" Options for ale ------------------------------------------------------------
let g:ale_set_loclist=0
let g:ale_echo_cursor=0
let g:ale_hover_cursor=0
let g:ale_cursor_detail=0
let g:ale_virtualtext_cursor='disable'

let g:ale_floating_preview=1
let g:ale_floating_window_border=['│', '─', '╭', '╮', '╯', '╰', '│', '─']

let g:ale_completion_symbols = {
    \ 'text': '',
    \ 'method': '',
    \ 'function': '',
    \ 'constructor': '',
    \ 'field': '',
    \ 'variable': '',
    \ 'class': '',
    \ 'interface': '',
    \ 'module': '',
    \ 'property': '',
    \ 'unit': 'unit',
    \ 'value': 'val',
    \ 'enum': '',
    \ 'keyword': 'keyword',
    \ 'snippet': '',
    \ 'color': 'color',
    \ 'file': '',
    \ 'reference': 'ref',
    \ 'folder': '',
    \ 'enum member': '',
    \ 'constant': '',
    \ 'struct': '',
    \ 'event': 'event',
    \ 'operator': '',
    \ 'type_parameter': 'type param',
    \ '<default>': 'v'
    \ }

let g:ale_floating_preview_popup_opts = {
    \ 'close': 'none'
    \ }

let g:ale_linters_ignore = {
    \   'html': ['eslint'],
    \}

set omnifunc=ale#completion#OmniFunc

nmap gh <Plug>(ale_hover)
nmap gH <Plug>(ale_detail)
nmap gR <Plug>(ale_find_references)
nmap gD <Plug>(ale_go_to_definition)
nmap gY <Plug>(ale_go_to_type_definition)

nmap [e <Plug>(ale_previous)
nmap [E <Plug>(ale_first)
nmap ]e <Plug>(ale_next)
nmap ]E <Plug>(ale_last)

" Options for jsbeautify -----------------------------------------------------
function! s:FormatJS()
    if mode() == 'n'
        call Beautifier('js', v:lnum, v:lnum + v:count - 1)
        return 0
    endif
    return 1
endfun
function! s:FormatJSX()
    if mode() == 'n'
        call Beautifier('jsx', v:lnum, v:lnum + v:count - 1)
        return 0
    endif
    return 1
endfun
function! s:FormatCSS()
    if mode() == 'n'
        call Beautifier('css', v:lnum, v:lnum + v:count - 1)
        return 0
    endif
    return 1
endfun
function! s:FormatHTML()
    if mode() == 'n'
        call Beautifier('html', v:lnum, v:lnum + v:count - 1)
        return 0
    endif
    return 1
endfun
function! s:FormatJSON()
    if mode() == 'n'
        call Beautifier('json', v:lnum, v:lnum + v:count - 1)
        return 0
    endif
    return 1
endfun

augroup vimrc_plugin_jsbeautify_setup
    autocmd!
    autocmd FileType javascript         setlocal formatexpr=s:FormatJS()
    autocmd FileType typescript         setlocal formatexpr=s:FormatJS()
    autocmd FileType javascriptreact    setlocal formatexpr=s:FormatJSX()
    autocmd FileType typescriptreact    setlocal formatexpr=s:FormatJSX()
    autocmd FileType css                setlocal formatexpr=s:FormatCSS()
    autocmd FileType html               setlocal formatexpr=s:FormatHTML()
    autocmd FileType json               setlocal formatexpr=s:FormatJSON()
augroup end

" Options for 'splitjoin' ----------------------------------------------------
let g:splitjoin_join_mapping='gS'
let g:splitjoin_split_mapping='gs'

" Options for lightline ------------------------------------------------------
let g:lightline = {
    \ 'colorscheme': g:colors_name,
    \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
    \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
    \ }

let g:lightline.component_expand = {
    \  'linter_checking':  'lightline#ale#checking',
    \  'linter_infos':     'lightline#ale#infos',
    \  'linter_warnings':  'lightline#ale#warnings',
    \  'linter_errors':    'lightline#ale#errors',
    \  'linter_ok':        'lightline#ale#ok',
    \ }

let g:lightline.component_type = {
    \  'linter_checking':  'right',
    \  'linter_infos':     'right',
    \  'linter_warnings':  'warning',
    \  'linter_errors':    'error',
    \  'linter_ok':        'right',
    \ }

let g:lightline.active = {
    \ 'right': [
    \   [
    \       'linter_checking',
    \       'linter_errors',
    \       'linter_warnings',
    \       'linter_infos',
    \       'linter_ok'
    \   ],
    \   ['lineinfo'],
    \   ['percent'],
    \   ['fileformat', 'fileencoding', 'filetype']
    \  ]
    \ }

let g:lightline#ale#indicator_checking = "\uf110 "
let g:lightline#ale#indicator_infos    = "\uf129 "
let g:lightline#ale#indicator_warnings = "\uf071 "
let g:lightline#ale#indicator_errors   = "\uf05e "

" Options for 'highlightedyank' ----------------------------------------------
let g:highlightedyank_highlight_duration=200

" ============================================================================
if executable('rg')
    let g:ackprg = "rg --vimgrep"
    let $FZF_DEFAULT_COMMAND = 'rg --files'
elseif executable('ag')
    let g:ackprg = "ag --vimgrep"
    let $FZF_DEFAULT_COMMAND = 'ag -g ""'
endif

" ============================================================================
function! s:SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfunction

nnoremap <leader>? :call <SID>SynGroup()<CR>

" ============================================================================
