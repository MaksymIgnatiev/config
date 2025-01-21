#!/bin/sh

ESC=$(printf '\033')
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
NC="${ESC}[0m"
QUIET="false"
FORCE="false"

[ ! -z $1 ] && [ "$1" = "true" ] && QUIET="true"
[ ! -z $2 ] && [ "$2" = "true" ] && FORCE="true"

print() {
	[ $QUIET = "false" ] && echo $1
	return 0
}
command -v git 2>&1 >/dev/null || print "${YELLOW}Git is not installed. Exiting$NC" && exit 0

[ ! -d "~/.tmux/plugins/tpm" ] && \
	print "${YELLOW}Insalling tpm (Tmux Plugin Manager)...$NC" && \
	git clone -q https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
	print "${GREEN}Successfully installed 'tmp'.${NC}" 

print "${YELLOW}Insalling tmux plugins...$NC"
[ -f "~/.tmux/plugins/tpm/scripts/install_plugins.sh" ] && tmux run-shell ~/.tmux/plugins/tpm/scripts/install_plugins.sh 2>1 >/dev/null
print "${GREEN}Successfully installed tmux plugins.${NC}" 

unset print ESC GREEN YELLOW NC QUIET

exit 0
