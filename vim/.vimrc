set belloff=all
set number
set relativenumber
set mouse=a
set laststatus=2
set wrap
set tabstop=4
set ignorecase
set smartcase
set signcolumn=yes
let mapleader = " "

let s:config_dir = $HOME . ".config/vim/config"
let s:file = ""

for file in split(glob(s:config_dir . "/*.vim"), "\n")
    execute 'source' s:file
endfor

unlet s:config_dir
unlet s:file


" If plug is not installed - don't throw an error
try

call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'scrooloose/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/syntastic'
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'lewis6991/gitsigns.nvim'

call plug#end()

catch
endtry

set background=dark
let g:gruvbox_contrast_dark = 'hard'

syntax enable

try
	colorscheme gruvbox
catch
	colorscheme default
endtry

" Some usefool keybinds

" Normal mode
nnoremap J mzJ`z
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv

nnoremap <leader>y "+y
nnoremap <leader>Y "+Y

nnoremap <leader>d "_d

" Visual mode
vnoremap <leader>y "+y
vnoremap <leader>Y "+Y

vnoremap <leader>d "_d

vnoremap <leader>r "_di

" Move selected area up/down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv


" Insert mode
inoremap <C-c> <Esc>


" Gitsigns
" lua require('gitsigns').setup()

" highlight GitSignsAdd     guifg=#00FF00  guibg=NONE
" highlight GitSignsChange  guifg=#FFFF00  guibg=NONE
" highlight GitSignsDelete  guifg=#FF0000  guibg=NONE
" highlight GitSignsAddNr   guifg=#00FF00  guibg=NONE
" highlight GitSignsChangeNr guifg=#FFFF00  guibg=NONE
" highlight GitSignsDeleteNr guifg=#FF0000  guibg=NONE
" highlight GitSignsAddLn   guibg=#003300
" highlight GitSignsChangeLn guibg=#333300
" highlight GitSignsDeleteLn guibg=#330000

" Set a highlight group with optional colors and GUI attributes
" For any optional value that needs to be missing - use `''`
" @param {string} group - The highlight group name
" @param {string} [fg] - Foreground color (optional)
" @param {string} [bg] - Background color (optional)
" @param {string} [gui] - GUI attributes like bold, italic, underline (optional, listed coma separated)
function! SetHighlight(group, fg, bg, gui) abort
    let l:cmd = 'highlight ' . a:group

    if !empty(a:fg)
        let l:cmd .= ' guifg=' . a:fg
    endif

    if !empty(a:bg)
        let l:cmd .= ' guibg=' . a:bg
    endif

    if !empty(a:gui)
        let l:cmd .= ' gui=' . a:gui
    endif

    execute l:cmd
endfunction





" call SetHighlight('GitSignsAdd'      , '#00FF00')
" call SetHighlight('GitSignsChange'   , '#FFFF00')
" call SetHighlight('GitSignsDelete'   , '#FF0000')
" call SetHighlight('GitSignsAddNr'    , '#00FF00')
" call SetHighlight('GitSignsChangeNr' , '#FFFF00')
" call SetHighlight('GitSignsDeleteNr' , '#FF0000')
" call SetHighlight('GitSignsAddLn'    ,  '', '#003300')
" call SetHighlight('GitSignsChangeLn' ,  '', '#333300')
" call SetHighlight('GitSignsDeleteLn' ,  '', '#330000')

call SetHighlight('Normal' , '#AAFFAA', '#001100', '')

