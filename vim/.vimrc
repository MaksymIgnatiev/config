set belloff=all
set number
set relativenumber
set mouse=a
set laststatus=2
set wrap
set tabstop=4

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
