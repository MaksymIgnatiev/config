#!/bin/sh

ESC=$(printf '\033')
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
CYAN="${ESC}[36m"
GRAY="${ESC}[38;5;245m"
NC="${ESC}[0m"
QUIET="false"

(command -v git >/dev/null 2>&1 || echo "${YELLOW}git is not installed. Skipping...$NC" && exit 2)

[ ! -z $1 ] && [ "$1" = "true" ] && QUIET="true"

# Needed plugins. 
# Format: plugin repo
# Plugin pairs are separated by newline
PLUGIN_REPOS="
zsh-autosuggestions      https://github.com/zsh-users/zsh-autosuggestions.git
zsh-syntax-highlighting  https://github.com/zsh-users/zsh-syntax-highlighting.git
powerlevel10k            https://github.com/romkatv/powerlevel10k.git
"


print() {
	( [ $QUIET = "false" ] && echo $1 )
	return 0
}

ZSH_DIR="$HOME/.zsh"
[ ! -d "$ZSH_DIR" ] && (mkdir -p "$ZSH_DIR" && print "${GREEN}Created $ZSH_DIR directory.${NC}" || exit 1) 

# return code:
# 0 = installed
# 1 = failure/skipped
install_plugin() {
	local plugin=$1
	local repo=$2
	local plugin_path="$ZSH_DIR/$plugin"

	[ -d "$plugin_path" ] && return 1
	print "${YELLOW}Installing zsh plugin '$plugin'${NC}"
	(git clone -q "$repo" "$plugin_path" 2>&1 > /dev/null &&\
		print "${GREEN}Successfully installed '$plugin'.${NC}" && return 0 ||\
		print "${RED}Failed to install '$plugin'. Please check your internet connection and permissions.${NC}" && return 1)
}


installed=0

tmp_file=$(mktemp)
echo "$PLUGIN_REPOS" > $tmp_file

while read -r plugin repo; do
	[ -z "$plugin" ] || [ -z "$repo" ] && continue
	install_plugin "$plugin" "$repo" && installed=$(expr $installed + 1) 
done < $tmp_file

rm $tmp_file 2>&1 > /dev/null 

[ $installed -gt 0 ] && print "$GREEN$installed zsh plugin$([ ! $installed -eq 1 ] && echo "s") installed.$NC"

unset install_plugin ZSH_DIR

exit 0
