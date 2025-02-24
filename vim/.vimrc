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

" If plug is not installed - don't throw an error
try

call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', { 'branch': 'release'}
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
inoremap <expr> <C-Space> coc#refresh()
inoremap <C-c> <Esc>
inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "<S-Tab>"
inoremap <expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "<CR>"
inoremap <expr> <C-y> coc#pum#visible() ? coc#pum#confirm() : "<C-y>"


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

