#!/bin/sh

trap 'exit 0' INT

ESC=$(printf '\033')
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
CYAN="${ESC}[36m"
GRAY="${ESC}[38;5;245m"
NC="${ESC}[0m"

SETUP_QUIET="false"
EXTRA="true"
REMOVE="false"
FORCE_SETUP="false"

# Required tools for this script to work properly
REQUIRED_TOOLS="realpath readlink"

# who knows where this config was pulled from, therefore, check for git
OPTIONAL_TOOLS="git curl wget"

# List of all categories that needs to be excluded from being invoked (separated by space)
CATEGORY_EXCLUDE="pictures"
CATEGORY_EXCLUDE=""

DIRS=$(find . -maxdepth 1 -type d ! -name '.*' | xargs -n 1 basename | sort | tr '\n' ' ') 
CATEGORY_EXCLUDE=$(echo $CATEGORY_EXCLUDE | xargs)
[ "$CATEGORY_EXCLUDE" != "" ] && DIRS=$(echo $DIRS | sed "s/$(echo $CATEGORY_EXCLUDE | sed 's/ \+/\\|/g')//g" )
CATEGORY_ALL="true"
CATEGORY_TRUE=""
CATEGORY=""


print_help() {
	echo "Usage: $GREEN$0$NC $GREEN[flag...] [category...]$NC"
	echo "Setups/removes the config files, optionaly for certain category(-ies) (see ${GREEN}CATEGORY$NC)"
	echo "FLAGS:"
	echo "${GREEN}-h, --help$NC        Print this help message"
	echo "${GREEN}-q, --quiet$NC       Do setup before linking quiet"
	echo "${GREEN}-n, --nowarning$NC   Skip files that are already configured (setup), or don't show the warning when trying to remove non-existent file (remove)"
	echo "${GREEN}-r, --remove$NC      Remove links (for certain category, if needed)"
	echo "${GREEN}-a, --additional$NC  Perform forced additional setup for needed categories(-ry)"
	echo "CATEGORY:"
	for _dir in $DIRS; do printf "${GREEN}$(basename "${_dir%/}")$NC "; done && echo ""
}


parse_arg() {
	case "$1" in
		-h | --[Hh][Ee][Ll][Pp]) print_help && exit 0 ;;
		-q | --[Qq][Uu][Ii][Ee][Tt]) SETUP_QUIET="true" ;;
		-n | --[Nn][Oo][Ww][Aa][Rr][Nn][Ii][Nn][Gg]) EXTRA="true" ;;
		-r | --[Rr][Ee][Mm][Oo][Vv][Ee]) REMOVE="true" ;;
		-a | --[Aa][Dd][Dd][Ii][Tt][Ii][Oo][Nn][Aa][Ll]) FORCE_SETUP="true" ;;
		-* | --*) echo "${YELLOW}Unknown flag: '$1'" && exit 0 ;;
		*) 
			echo "$DIRS" | grep -q -w "$1" && \
				CATEGORY_ALL="false" && CATEGORY_TRUE="$CATEGORY_TRUE $1" || \
				{ echo "${YELLOW}Not a category: '$1'$NC" && return 0; } ;;
	esac
}

while [ $# -gt 0 ]; do
	case "$1" in
		-[a-zA-Z]*)
			args="${1#-}"
			while [ -n "$args" ]; do
				arg="-${args%${args#?}}"
				args="${args#?}"
				parse_arg $arg
			done
			;;
		*) parse_arg $1 ;;
	esac
	shift
done

for tool in $REQUIRED_TOOLS; do 
	command -v $tool >/dev/null 2>&1 || echo "${YELLOW}Tool '$tool' is required for setup script.$NC"
done

CONFIG_DIR="${CONFIG:-$XDG_CONFIG_HOME}"
 

[ "$CONFIG_DIR" != "" ] && \
	([ ! -d "$CONFIG_DIR" ] && echo "${RED}Configuration directory '$CONFIG_DIR' is not a directory.${NC}" && exit 1) || \
	CONFIG_DIR="$HOME/.config"

check_and_create_dir() {
	[ -z "$1" ] && return 1
	[ -d "$1" ] && return 0

	printf "${YELLOW}Directory $1/ does not exist. Create it? [Y/n]:$NC "
	read -r create_dir
	case "$create_dir" in
		[Yy] | [Yy][Ee][Ss] | "") mkdir -p "$1" && echo "${GREEN}Created: $1/$NC" && return 0 ;;
		[Nn] | [Nn][Oo]) echo "Skipped creating $1" && return 1 ;;
		*) echo "Invalid input. Skipping..." && return 1 ;;
	esac
	return 0
}

backup_file() {
	target="$1"
	[ -z "$target" ] && return 1
	backup_name="${target}_$(date +"%Y.%m.%d_%H:%M:%S").backup"
	mv "$target" "$backup_name" && echo "${YELLOW}Backup created: $backup_name$NC"
}

resolve_path() {
	input_path="$1"
	[ -z "$input_path" ] && return 1
	realpath -s "$input_path" 2>/dev/null || return 1
	return 0
}

category_enabled() {
	[ -z "$1" ] && return 0
	[ $CATEGORY_ALL = "true" ] || echo "$CATEGORY_TRUE" | grep -q -w "$1"
	return $?
}

# Allows or disallows to execute the setup script for specific category based on provided `$CATEGORY` and `$REMOVE`
setup_script() {
	[ -z $1 ] && return 1
	[ $REMOVE = "false" ] && category_enabled $1 
	return $?
}

# returns a 0 or 1 return code as indication to allow output extra information (warnings, extra steps)
extra_info() {
	[ $EXTRA = "true" ]
	return $?
}

# Manage a symlink to a file
# Depending on flags, it will:
# - create symlink with asking for a backup
# - create symlink for needed rest (only those who are not yet linked)
# - remove symlink
# - remove symlink without warnings for non-existent files
# Usage:
# manage_symlink /absolute/path/to/source  /absolute/path/to/destination
# manage_symlink relative/path/to/source   /absolute/path/to/destination
# manage_symlink ./relative/path/to/source ./relative/path/to/destination
# manage_symlink /absolute/path/to/source  relative/path/to/destination
#
# Note! When removing link, it performs check on wether file is a link, and points to a specific (given to a function) file in config. So regular files and symlinks that points to a different location will not be removed
manage_symlink() {
	[ $# -lt 2 ] && echo "${RED}manage_symlink: Too few arguments. Usage: manage_symlink path/to/source path/to/destination$NC" && return 1

	source="$(resolve_path $1)"
	target="$(resolve_path $2)"

	category_enabled "$CATEGORY" || return 0
	[ -z $source ] || [ ! -e $source ] && echo "${RED}Source does not exist: '$source'$NC" && return 1
	target_dir=$(dirname "$target")
	check_and_create_dir "$target_dir" || return 1

	if [ -e $target ]; then
		if [ $REMOVE = "true" ]; then
			[ -L $target ] && \
				{
					[ $(readlink $target) = $source ] && \
					rm $target && echo "${GREEN}Removed symlink:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC" || \
					extra_info && echo "${YELLOW}Link $target points to a different location. Skipping...$NC"
				} || extra_info && echo "${YELLOW}File $target is not a symlink. Skipping...$NC"
		else
			extra_info && return 0
			printf "${YELLOW}Target already exists: $target. Replace (backup old)? [Y/n]:$NC "
			read -r replace
			case "$replace" in
				[Yy] | [Yy][Ee][Ss] | "") backup_file "$target" && ln -sf "$source" "$target" ;;
				[Nn] | [Nn][Oo]) echo "Skipped: $target" && return 0 ;;
				*) echo "Invalid input. Skipping..." && return 0 ;;
			esac
		fi
	else
		[ $REMOVE = "false" ] && \
			ln -s "$source" "$target" && \
			echo "${GREEN}Symlink created:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC" || \
			(extra_info && echo "${YELLOW}Could't find the destination to unlink: $target$NC")
	fi
}


# How to use config files and manage them:
# 1. Set $CATEGORY variable to a desired category that will be configured
#
# 2. Add custom setup scripts with following syntax:
# ```sh
# setup_script category_name && path/to/setup/script
# ```
#
# 3. Add custom symlink managing with the following syntax:
# ```sh
# manage_symlink path/to/source path/to/destination
# ```
# Note! `manage_symlink` function can symlink not only files, but directories also. See implementation
#
# 4. Add post setup scripts with the previously shown syntax as in point 2.


# Per-category setup


CATEGORY="fastfetch"

# Fastfetch
manage_symlink ./fastfetch/config.jsonc $CONFIG_DIR/fastfetch/config.jsonc
manage_symlink ./fastfetch/logo.png $CONFIG_DIR/fastfetch/logo.png


CATEGORY="i3"

# i3
manage_symlink ./i3/config $CONFIG_DIR/i3/config


CATEGORY="kitty"

# Kitty
manage_symlink ./kitty/kitty.conf $CONFIG_DIR/kitty/kitty.conf


CATEGORY="polybar"

# Polybar
manage_symlink ./polybar/config.ini $CONFIG_DIR/polybar/config.ini
manage_symlink ./polybar/launch_polybar.sh $CONFIG_DIR/polybar/launch_polybar.sh

CATEGORY="rofi"

# Rofi
manage_symlink ./rofi/config.rasi $CONFIG_DIR/rofi/config.rasi
manage_symlink ./rofi/custom.rasi $CONFIG_DIR/rofi/custom.rasi

CATEGORY="tmux"

# Tmux configuration
manage_symlink ./tmux/.tmux.conf $HOME/.tmux.conf

# Tmux post setup script
setup_script tmux && ./.setup/tmux.sh $SETUP_QUIET


CATEGORY="vim"

# Vim setup
manage_symlink ./vim/.vimrc $HOME/.vimrc

# Vim post setup script
# automaticaly installs vim-plug, and if vim installed - installs all needed plugins (that are listed in `.vimrc` file)
setup_script vim && ./.setup/vim.sh $SETUP_QUIET


CATEGORY="zsh"

# ZSH Config path (just alias to not write full path every time)
ZSHC="$CONFIG_DIR/zsh"

# Zsh setup
# Initialises directory, and installs needed plugins
setup_script zsh && ./.setup/zsh.sh $SETUP_QUIET

# Zsh configuration

manage_symlink ./zsh/.zprofile      $HOME/.zprofile
manage_symlink ./zsh/.zshrc         $HOME/.zshrc
manage_symlink ./zsh/.zshenv        $ZSHC/.zshenv
manage_symlink ./zsh/.zsh_aliases   $ZSHC/.zsh_aliases
manage_symlink ./zsh/.zsh_variables $ZSHC/.zsh_variables
manage_symlink ./zsh/.zsh_path      $ZSHC/.zsh_path
manage_symlink ./zsh/.zsh_functions $ZSHC/.zsh_functions

manage_symlink ./zsh/.p10k.zsh      $HOME/.p10k.zsh

unset print_help manage_symlink resolve_path category_enabled parse_arg check_and_create_dir backup_file ZSHC SETUP_QUIET EXTRA REMOVE DIRS CATEGORY CATEGORY_ALL CATEGORY_TRUE category_enabled extra_info CATEGORY_EXCLUDE

exit 0
