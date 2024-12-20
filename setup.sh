#!/bin/sh

on_sigint() {
	unset on_sigint
    exit 0
}

trap 'on_sigint' INT

ESC=$(printf '\033')
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
CYAN="${ESC}[36m"
GRAY="${ESC}[38;5;245m"
NC="${ESC}[0m"

# ZSH Config path
ZSHC="$HOME/.config/zsh"

SETUP_QUIET="false"
APPEND="false"
REMOVE="false"

DIRS=$(ls -d */ | tr -d '/' | tr '\n' ' ')
CATEGORY_ALL="true"
CATEGORY_TRUE=""
CATEGORY=""


print_help() {
	echo "Perform a setup on all configs, or on picked categories"
	echo "Usage: $GREEN./setup.sh$NC $GREEN[flags...] | -[short flag sequence] [category...]$NC"
	echo "FLAGS:"
	echo "${GREEN}-h, --help$NC      Print this help message"
	echo "${GREEN}-q, --quiet$NC     Do setup before linking quiet (zsh/vim setup)"
	echo "${GREEN}-a, --add$NC       Add missing links without changing old ones and making new backups"
	echo "${GREEN}-r, --remove$NC    Remove all links"
	echo "CATEGORY:"
	for _dir in $(ls -d */); do printf "${GREEN}$(basename "${_dir%/}")$NC "; done && echo ""
}

parse_arg() {
	case "$1" in
		-h | --[Hh][Ee][Ll][Pp]) print_help && exit 0 ;;
		-q | --[Qq][Uu][Ii][Ee][Tt]) SETUP_QUIET="true" ;;
		-a | --[Aa][Pp][Pp][Ee][Nn][Dd]) APPEND="true" ;;
		-r | --[Rr][Ee][Mm][Oo][Vv][Ee]) REMOVE="true" ;;
		-* | --*) echo "${YELLOW}Unknown flag: '$1'" && exit 0 ;;
		*) 
			echo "$DIRS" | grep -q -w "$1" && \
				CATEGORY_ALL="false" && CATEGORY_TRUE="$CATEGORY_TRUE $1" || \
				{ echo "${YELLOW}Not a category: '$1'$NC" && exit 0; } ;;
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

HOME_DIR="${HOME:?$YELLOW\$HOME is not set. Check your environment!$NC}"
CONFIG_DIR="${CONFIG:-$XDG_CONFIG_HOME}"
[ -z "$CONFIG_DIR" ] && CONFIG_DIR="$HOME/.config"

if [ ! -d "$CONFIG_DIR" ]; then
	echo "${YELLOW}Configuration directory not found: $CONFIG_DIR$NC"
	echo "Fallback to default: $HOME/.config"
	CONFIG_DIR="$HOME/.config"
	if [ ! -d "$CONFIG_DIR" ]; then
		echo "${RED}Cannot find or create configuration directory.${NC}"
		exit 1
	fi
fi

check_and_create_dir() {
	[ -z "$1" ] && return 1
	if [ ! -d "$1" ]; then
		printf "Directory %s does not exist. Create it? [Y/n] " "$1"
		read -r create_dir
		case "$create_dir" in
			[Yy] | [Yy][Ee][Ss] | "") mkdir -p "$1" && echo "${GREEN}Created: $1$NC" && return 0 ;;
			[Nn] | [Nn][Oo]) echo "Skipped creating $1" && return 1 ;;
			*) echo "Invalid input. Skipping..." && return 1 ;;
		esac
	fi
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
	(
	case "$input_path" in
		/*) cd "$(dirname "$input_path")" && echo "$(pwd)/$(basename "$input_path")" || echo "" ;;
		*) cd "$(pwd)/$(dirname "$input_path")" && echo "$(pwd)/$(basename "$input_path")" || echo "" ;;
	esac
	) 2>/dev/null || return 1
}

category_enabled() {
	[ -z "$1" ] && return 0
	return $([ $CATEGORY_ALL = "true" ] || echo "$CATEGORY_TRUE" | grep -q -w "$1" && echo "$?")
}

# Manage a symlink to a file
# Depending on flags, it will:
# - create symlink with asking for a backup
# - create symlink for needed rest (only those who are not yet linked)
# - remove symlink
# Usage:
# manage_symlink /absolute/path/to/source  /absolute/path/to/destination
# manage_symlink relative/path/to/source   /absolute/path/to/destination
# manage_symlink ./relative/path/to/source ../relative/path/to/destination
# manage_symlink /absolute/path/to/source  relative/path/to/destination
manage_symlink() {
	source="$(resolve_path $1)"
	target="$(resolve_path $2)"
	
	category_enabled "$CATEGORY" || return 0
	[ -z $source ] || [ ! -e $source ] && echo "${RED}Source does not exist: '$source'$NC" && return 1

	target_dir=$(dirname "$target")
	check_and_create_dir "$target_dir" || return 1

	if [ -e $target ]; then
		if [ $REMOVE = "true" ]; then
			rm $target && echo "${GREEN}Removed symlink:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC"
		else
			[ $APPEND = "true" ] && return 0
			printf "${YELLOW}Target already exists: $target. Replace (backup old)? [Y/n]:$NC "
			read -r replace
			case "$replace" in
				[Yy] | [Yy][Ee][Ss] | "") backup_file "$target" && ln -sf "$source" "$target" ;;
				[Nn] | [Nn][Oo]) echo "Skipped: $target" && return 0 ;;
				*) echo "Invalid input. Skipping..." && return 0 ;;
			esac
		fi
	else
		[ $REMOVE = "false" ] && ln -s "$source" "$target" && echo "${GREEN}Symlink created:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC" || \
			echo "${YELLOW}Could't find the destination to unlink: $target$NC"
	fi
}


CATEGORY="zsh"

# Zsh setup

[ $REMOVE = "false" ] && category_enabled zsh && ./.setup/zsh.sh $SETUP_QUIET

# Zsh configuration

manage_symlink ./zsh/.zprofile      $HOME/.zprofile
manage_symlink ./zsh/.zshrc         $ZSHC/.zshrc
manage_symlink ./zsh/.zshenv        $ZSHC/.zshenv
manage_symlink ./zsh/.zsh_aliases   $ZSHC/.zsh_aliases
manage_symlink ./zsh/.zsh_variables $ZSHC/.zsh_variables
manage_symlink ./zsh/.zsh_path      $ZSHC/.zsh_path
manage_symlink ./zsh/.zsh_functions $ZSHC/.zsh_functions

manage_symlink ./zsh/.p10k.zsh      $HOME/.p10k.zsh


CATEGORY="tmux"

# Tmux
manage_symlink ./tmux/.tmux.conf $HOME/.tmux.conf


CATEGORY="kitty"

# Kitty
manage_symlink ./kitty/kitty.conf $HOME/.config/kitty/kitty.conf


CATEGORY="i3"

# i3
manage_symlink ./i3/config $HOME/.config/i3/config


CATEGORY="vim"

# Vim
manage_symlink ./vim/.vimrc $HOME/.vimrc
[ $REMOVE = "false" ] && category_enabled vim && ./.setup/vim.sh $SETUP_QUIET

exit 0
