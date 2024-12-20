#!/bin/sh

ESC=$(printf '\033')
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
CYAN="${ESC}[36m"
GRAY="${ESC}[38;5;245m"
NC="${ESC}[0m"
QUIET="false"

[ ! -z $1 ] && [ "$1" = "true" ] && QUIET="true"

install_via_git() {
	local tmp_dir="$(mktemp -d)"
	git clone -q https://github.com/junegunn/vim-plug.git $tmp_dir
	cp "$tmp_dir/plug.vim" "$HOME/.vim/autoload/"
	rm -rf $tmp_dir
}

print() {
	( [ $QUIET = "false" ] && echo $1 )
	return 0
}

_setup() {

	CURL_INSTALLED="$(command -v curl 2>&1 >/dev/null && echo "true" || echo "false")" 
	GIT_INSTALLED="$(command -v git 2>&1 >/dev/null && echo "true" || echo "false")" 

	[ $CURL_INSTALLED = "false" ] && [ $GIT_INSTALLED = "false" ] && print "${YELLOW}Neither curl or git are installed. Skipping...$NC" && return 0

	(
	print "${YELLOW}Installing vim-plug...$NC"
	mkdir -p "$HOME/.vim/autoload"
	[ $CURL_INSTALLED = "true" ]  && curl -sfLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || \
		([ $GIT_INSTALLED = "true" ] && install_via_git)

	) && (
	print "${GREEN}Vim-plug installed successfully.$NC"
	command -v vim 2>&1 >/dev/null && \
		print "${YELLOW}Installing vim plugins...$NC" && \
		vim --not-a-term +'autocmd VimEnter * if argc() == 0 | PlugInstall --sync | qall | endif' 2>&1 >/dev/null && \
		print "${GREEN}Vim plugins installed successfully.$NC"

	)	
}

[ ! -f "$HOME/.vim/autoload/plug.vim" ] && _setup

unset install_via_git _setup print
