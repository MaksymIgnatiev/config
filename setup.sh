#!/usr/bin/env bash


ESC=""
RED="$ESC[31m"
YELLOW="$ESC[33m"
GREEN="$ESC[32m"
BLUE="$ESC[34m"
NC="$ESC[0m"
readonly CURENT=$(pwd)
HOME_DIR=""
CONFIG_DIR=""


if [[ -z "$HOME" ]]; then
	echo -e "$YELLOW\$HOME environment variable is not set$NC"
	read -p "Which directory can be used as a home directory? (you can use environment variables as a values) (blank=none): " home_dir_answer
	if [[ $home_dir_answer =~ \$[a-zA-Z0-9_]+ ]]; then
		eval "home_dir_answer=$home_dir_answer"
		[[ -d $home_dir_answer ]] && echo -e "Using $GREEN'$home_dir_answer'$NC as a home directory" && HOME_DIR=$home_dir_answer || echo -e "Path $YELLOW'$home_dir_answer'$NC is not a valid path to directory"
	else
	[[ -n $home_dir_answer ]] && [[ -d $home_dir_answer ]] && echo -e "Using $GREEN'$home_dir_answer'$NC as a home directory" && HOME_DIR=$home_dir_answer 
	fi
	[[ -z "$HOME_DIR" ]] && echo -e "This script is not configured to read minds. Please configure all files by yourself, or set environment variable $YELLOW\$HOME${NC} to continue.\nYou can use following syntax to provide a variable once: ${GREEN}HOME=/path/to/home/directory ./script.sh$NC" && exit 1
else
	HOME_DIR=$HOME
fi

[[ -n "$CONFIG" ]] && [[ -d $CONFIG ]] && CONFIG_DIR=$CONFIG
[[ -z $XDG_CONFIG_HOME ]] && XDG_CONFIG_HOME=$HOME/.config
if [[ -z $CONFIG_DIR ]] && ! [[ -d $XDG_CONFIG_HOME ]]; then
	echo -e "$YELLOW\$XDG_CONFIG_HOME is not set, and fallback directory '\$HOME/.config/' can't be foud$NC"
	read -p "What directory can be used as a config directory? (you can use environment variables as a values) (blank=none): " config_dir_answer
	if [[ $config_dir_answer =~ \$[a-zA-Z0-9_]+ ]]; then
		eval "config_dir_answer=$config_dir_answer"
		[[ -d $config_dir_answer ]] && "Using $GREEN'$config_dir_answer'$NC as a config directory" && CONFIG_DIR=$config_dir_answer
	else
		[[ -n $home_dir_answer ]] && [[ -d $config_dir_answer ]] && echo -e "Using $GREEN'$config_dir_answer'$NC as a config directory" && CONFIG_DIR=$config_dir_answer || echo -e "$YELLOW'$config_dir_answer'$NC is not a valid directory"
	fi
	[[ -z "$CONFIG_DIR" ]] && echo -e "This script is not configured to read minds. Please configure all files by yourself, or set environment variable $YELLOW\$XDG_CONFIG_HOME${NC} or $YELLOW\$CONFIG$NC to continue.\nYou can use following syntax to provide a variable once: ${GREEN}CONFIG=/path/to/config/directory ./script.sh$NC" && exit 1
else
	[[ -n $XDG_CONFIG_HOME ]] && [[ -d $XDG_CONFIG_HOME ]] && CONFIG_DIR=$XDG_CONFIG_HOME
	[[ -d "$HOME/.config" ]] && CONFIG_DIR="$HOME/.config"
fi


check_and_create_dir() {
	[[ -z $1 ]] && return 1
	if ! [[ -d $1 ]]; then
		read -p "Directory $YELLOW'$1'$NC does not exist. Would you like to create it? [Y/n] " create_dir
		[[ -z $create_dir ]] || [[ $create_dir =~ "[Yy](es)?" ]] && (mkdir -p $1 && echo -e "Created directory $GREEN'$1'$NC"; return 0)
		[[ $create_dir =~ [Nn]o? ]] && return 1
		echo "Invalid input. Skiping..." && return 1
	else 
		return 0
	fi
}

get_file_name() {
	[[ -z $1 ]] && return 1
	local filename="${1##*/}"
	echo "${filename%%.*}"
	return 0
}

get_file_extension() {
	[[ -z $1 ]] && return 1
	local filename="${1##*/}"
	[[ $filename == *.* ]] && echo "${filename##*.}" && return 0 || echo "" && return 1
}

create_symlink() {
	local source=$1
	local target=$2

	[[ -z $source ]] && echo -e "${RED}Path $YELLOW'$source'$RED does not exist$NC" && return 1
	[[ -z $target ]] && echo -e "${RED}Target $YELLOW'$target'$RED does not exist$NC" && return 1

	local target_dir
	[[ -f $target ]] && target_dir=$(dirname "$target") || target_dir=$target
	
	local file_name
	[[ -d $target ]] && file_name=$(basename $source) || file_name="$target_dir/$(get_file_name $([[ -d $target ]] && echo $source || echo $target))"
	local file_extension
	[[ -d $source ]] && file_extension="" || file_extension=$(get_file_extension $([[ -d $target ]] && echo $target || echo $source))
	local file_full_name=$file_name
	[[ -n $file_extension ]] && file_full_name+=".$file_extension"

	if [ -e "$target" ]; then
		local choise

		if [[ -d $target ]]; then
			echo -e "$GREEN'$target'$NC is a directory. File will be created insde it"
			ln -s $source $file_full_name
			echo -e "Created symlink $GREEN'$file_full_name'$NC -> $GREEN'$source'$NC"
		else

			[[ -f $target ]] && echo -e "File $YELLOW'$target'$NC already exist."
			read -p "Would you like to (${GREEN}R${NC})eplace (makes backup) or (${GREEN}S${NC})kip this file? [r/S]: " choise
			[[ -z $choise ]] || [[ $choise =~ [Ss](kip)? ]] && echo -e "Skipping $GREEN'$target'$NC" && return 1

			if [[ $choise =~ [Rr](eplace)? ]]; then
				file_name+="_$(date +"%d.%m.%Y_%H:%M:%S")"
				[[ -z $file_extension ]] && file_extension="backup" || file_extension+=".backup"
				file_full_name=$file_name.$file_extension	

				echo -e "Replacing ${GREEN}'$target'$NC (making backup)"
				mv $target "$target_dir/$file_full_name"
				echo -e "Created a backup file as $GREEN'$file_full_name'$NC"
				check_and_create_dir "$target_dir" || return 1
				ln -s $source $target
				echo -e "Created symlink $GREEN'$target'$NC"
			fi
		fi	
		echo -e "Invalid option. Skipping $GREEN'$target'$NC" && return 1
	else
		check_and_create_dir $target_dir || return 1
		ln -s $source $file_full_name
		echo -e "Created symlink for $GREEN'$target'$NC"
		return 0
	fi
}

# Usage:
# create_symlink source destination

# Zsh configuration
create_symlink /tmp/a/h.txt ~/.zshrc
create_symlink /tmp/b/h.txt ~/.zshrc
# create_symlink ~/config/zsh/.zshrc ~/.zshrc
# create_symlink ~/config/zsh/.zshenv ~/.zshenv
# create_symlink ~/config/zsh/.zsh_aliases ~/.config/zsh/.zsh_aliases
# create_symlink ~/config/zsh/.zsh_variables ~/.config/zsh/.zsh_variables
# create_symlink ~/config/zsh/.zsh_path ~/.config/zsh/.zsh_path
# create_symlink ~/config/zsh/.zsh_functions ~/.config/zsh/.zsh_functions

#create_symlink ~/config/zsh/.p10k.zsh ~/.p10k.zsh

# Tmux configuration
#create_symlink ~/config/tmux/.tmux.conf ~/.tmux.conf

# Kitty configuration
# create_symlink ~/config/kitty/kitty.conf ~/.config/kitty/kitty.conf

# i3 configuration
# create_symlink ~/config/i3/config ~/.config/i3/config
