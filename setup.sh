#!/bin/sh

trap 'exit 0' INT TERM

ESC=$(printf '\033')
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
CYAN="${ESC}[36m"
GRAY="${ESC}[38;5;245m"
NC="${ESC}[0m"

warning_color="$YELLOW"
answer_color="$GREEN"

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

	for _dir in $DIRS; do printf "${GREEN}$(basename "${_dir%/}")$NC "; done
	echo ""
}


parse_arg() {
	case "$1" in
		-h | --[Hh][Ee][Ll][Pp]) print_help && exit 0 ;;
		-q | --[Qq][Uu][Ii][Ee][Tt]) SETUP_QUIET="true" ;;
		-n | --[Nn][Oo][Ww][Aa][Rr][Nn][Ii][Nn][Gg]) EXTRA="false" ;;
		-r | --[Rr][Ee][Mm][Oo][Vv][Ee]) REMOVE="true" ;;
		-a | --[Aa][Dd][Dd][Ii][Tt][Ii][Oo][Nn][Aa][Ll]) FORCE_SETUP="true" ;;
		-* | --*) echo "${YELLOW}Unknown flag: '$1'" && exit 0 ;;
		*) 
			echo "$DIRS" | grep -q -w "$1" && {
				CATEGORY_ALL="false" && CATEGORY_TRUE="$CATEGORY_TRUE $1"
			} || { echo "${YELLOW}Not a category: '$1'$NC" && return 0; }
			;;
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

MISSING_REQUIRED_TOOLS=""
for tool in $REQUIRED_TOOLS; do 
	command -v $tool >/dev/null 2>&1 || MISSING_REQUIRED_TOOLS="$MISSING_REQUIRED_TOOLS $tool"
done
[ ${#MISSING_REQUIRED_TOOLS} -ne 0 ] && {
	echo "${YELLOW}There are some required tools missing:$NC"
	for tool in $MISSING_REQUIRED_TOOLS; do echo "    - $GREEN$tool$NC"; done
	echo "Consider installing them to use this script"
} && exit 0

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
	[ $FORCE_SETUP = "true" ] || [ $REMOVE = "false" ] && category_enabled $1 
	return $?
}

# Usage:
# extra_info && echo "Extra info will be shown" || echo "Extra info will not be shown"
#
# returns status code `0` if parameters allow to show extra info. Otherwise status code of `1`
extra_info() { [ $EXTRA = "true" ]; }

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
	[ $# -lt 2 ] && echo "${RED}manage_symlink$NC: Too few arguments (at: manage_symlink$([ ! -z "$1" ] && echo " $1")). Usage: manage_symlink path/to/source path/to/destination" && return 1

	source="$(resolve_path "$1")"
	target="$(resolve_path "$2")"

	category_enabled "$CATEGORY" || return 0
	[ -z $source ] || [ ! -e $source ] && echo "${RED}Source does not exist: '$source'$NC" && return 1
	target_dir=$(dirname "$target")
	check_and_create_dir "$target_dir" || return 1

	[ -L $target ] && other_target=$(readlink $target)

	# Target exists (dir/file/symlink)
	if [ -e $target ]; then

		[ $REMOVE = "true" ] && {
			[ -L $target ] && {
				[ "$other_target" = $source ] && {
					rm $target && echo "${GREEN}Removed symlink:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC"
				} || { extra_info && echo "${warning_color}Symlink $CYAN$target$warning_color points to a different location: $CYAN$other_target$warning_color. Skipping...$NC" ; }
			} || { extra_info && echo "${warning_color}File $target is not a symlink. Skipping...$NC" ; }
			return 0
		}

		extra_info || return 0
		
		local answer_options="y n S"
		local answer_question="${warning_color}Replace (${answer_color}y${warning_color}=backup old, ${answer_color}n${warning_color}=overwrite) or ${answer_color}S${warning_color}kip? [$(echo "$answer_options" | sed -E "s/([^ ]+)/${answer_color}\1${warning_color}/g; s/ /\\//g")${warning_color}]:"

		[ -L $target ] && {
			[ "$other_target" != $source ] && printf "${warning_color}Target $CYAN$target${warning_color} is a symlink, but points to a different location: $other_target\n$answer_question$NC $GREEN" || return 0
		} || printf "${YELLOW}Target already exists: $target\n$answer_question$NC $GREEN"

		read -r replace
		printf "$NC"
		case "$replace" in
			[Yy] | [Yy][Ee][Ss]) backup_file "$target" && ln -sf "$source" "$target" ;;
			[Nn] | [Nn][Oo]) ln -sf "$source" "$target" && echo "${GREEN}Replaced $CYAN$target$GREEN (symlink) to point to: $CYAN$source$NC" ;;
			[Ss] | [Ss][Kk][Ii][Pp] | "") echo "Skipped: $target" ;;
			*) echo "Invalid answer. Skipping..." ;;
		esac
	else
		# Target doesn't exist
		[ $REMOVE = "true" ] && {
			extra_info && echo "${YELLOW}Could't find the destination to unlink: $target$NC"
			return 0
		} 
		ln -s "$source" "$target" && echo "${GREEN}Symlink created:$NC $CYAN$target$NC $GRAY->$NC $CYAN$source$NC"
	fi
}


# How to use config files and manage them:
# 1. Set $CATEGORY variable to a desired category that will be configured
#
# 2. Add custom setup scripts before managing files with the following syntax:
# ```sh
# setup_script category_name && path/to/setup/script $SETUP_QUIET $FORCE_SETUP
# ```
# Note! Pay attension to the $SETUP_QUIET and $FORCE_SETUP ad the end. This are arguments that indicates quiet and forced setup respectfully
#
# 3. Add symlink managing with the following syntax:
# ```sh
# manage_symlink path/to/source path/to/destination
# ```
#
# 4. Add post setup scripts with the previously shown syntax as in point 2.

# Per-category setup

CATEGORY="dunst"

# Dunst
manage_symlink ./dunst/dunstrc $CONFIG_DIR/dunst/dunstrc


CATEGORY="fastfetch"

# Fastfetch
manage_symlink ./fastfetch/config.jsonc $CONFIG_DIR/fastfetch/config.jsonc
manage_symlink ./fastfetch/logo.png $CONFIG_DIR/fastfetch/logo.png


CATEGORY="i3"

# i3
manage_symlink ./i3/config $CONFIG_DIR/i3/config
manage_symlink ./i3/scripts/set_background.sh $CONFIG_DIR/i3/scripts/set_background.sh
manage_symlink ./i3/scripts/operate_on_current_screen.sh $CONFIG_DIR/i3/scripts/operate_on_current_screen.sh
manage_symlink ./i3/scripts/record.sh $CONFIG_DIR/i3/scripts/record.sh
manage_symlink ./i3/scripts/configure_touchpad.sh $CONFIG_DIR/i3/scripts/configure_touchpad.sh


CATEGORY="kitty"

# Kitty
manage_symlink ./kitty/kitty.conf $CONFIG_DIR/kitty/kitty.conf


CATEGORY="picom"

# Picom
manage_symlink ./picom/picom.conf $CONFIG_DIR/picom.conf


CATEGORY="polybar"

# Polybar
manage_symlink ./polybar/config.ini $CONFIG_DIR/polybar/config.ini
manage_symlink ./polybar/scripts/launch_polybar.sh $CONFIG_DIR/polybar/scripts/launch_polybar.sh
manage_symlink ./polybar/scripts/show-wifi.sh $CONFIG_DIR/polybar/scripts/show-wifi.sh
manage_symlink ./polybar/scripts/show-memory.sh $CONFIG_DIR/polybar/scripts/show-memory.sh
manage_symlink ./polybar/scripts/show_extra_info.sh $CONFIG_DIR/polybar/scripts/show_extra_info.sh


CATEGORY="rofi"

# Rofi
manage_symlink ./rofi/config.rasi $CONFIG_DIR/rofi/config.rasi
manage_symlink ./rofi/custom.rasi $CONFIG_DIR/rofi/custom.rasi


CATEGORY="tmux"

# Tmux configuration
manage_symlink ./tmux/.tmux.conf $HOME/.tmux.conf
manage_symlink ./tmux/clear-or-move.sh $CONFIG_DIR/tmux/clear-or-move.sh

# Tmux post setup script (plugins)
setup_script tmux && ./.setup/tmux.sh $SETUP_QUIET


CATEGORY="vim"

# Vim setup
manage_symlink ./vim/.vimrc $HOME/.vimrc

# Vim post setup script
# automaticaly installs vim-plug, and if vim is installed - installs all needed plugins (that are listed in `.vimrc` file)
setup_script vim && ./.setup/vim.sh $SETUP_QUIET


CATEGORY="zsh"

# ZSH Config path (just alias to not write full path every time)
ZSHC="$CONFIG_DIR/zsh"

# Zsh setup
# Installs needed plugins
setup_script zsh && ./.setup/zsh.sh $SETUP_QUIET

# Zsh configuration

# ~/.zprofile redirects zsh configuration to the `$XDG_CONFIG_HOME` / `$HOME/.config/` directory (to not mess up the home)
manage_symlink ./zsh/.zprofile      $HOME/.zprofile
manage_symlink ./zsh/.zshrc         $ZSHC/.zshrc
manage_symlink ./zsh/.zshenv        $ZSHC/.zshenv
manage_symlink ./zsh/.zsh_aliases   $ZSHC/.zsh_aliases
manage_symlink ./zsh/.zsh_variables $ZSHC/.zsh_variables
manage_symlink ./zsh/.zsh_path      $ZSHC/.zsh_path
manage_symlink ./zsh/.zsh_functions $ZSHC/.zsh_functions

manage_symlink ./zsh/.p10k.zsh      $HOME/.p10k.zsh


# Cleanup
unset print_help manage_symlink resolve_path category_enabled parse_arg check_and_create_dir backup_file ZSHC SETUP_QUIET EXTRA REMOVE DIRS CATEGORY CATEGORY_ALL CATEGORY_TRUE category_enabled extra_info CATEGORY_EXCLUDE

exit 0
