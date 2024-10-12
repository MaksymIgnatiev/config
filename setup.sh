#!/usr/bin/env bash

create_symlink() {
	local source=$1
	local target=$2

  if [ -e "$target" ]; then
	  echo -e "\033[33m$target\033[0m already exists."
	  read -p "Do you want to (R)eplace or (S)kip this file? (default=skip) " choice
	  case "$choice" in
		  R|r|Replace|replace)
			  echo -e "Replacing \033[32m$target\033[0m"
			  rm -f "$target"
			  ln -s "$source" "$target"
			  echo -e "Created symlink for \033[32m$target\033[0m"
			  ;;
		  ""|S|s|Skip|skip)
			  echo -e "Skipping \033[32m$target\033[0m"
			  ;;
		  *)
			  echo -e "Invalid option. Skipping \033[32m$target\033[0m"
			  ;;
	  esac
  else
	  ln -s "$source" "$target"
	  echo -e "Created symlink for \033[32m$target\033[0m"
  fi
}

# Zsh configuration
create_symlink ~/config/zsh/.zshrc ~/.zshrc
create_symlink ~/config/zsh/.zshenv ~/.zshenv
create_symlink ~/config/zsh/.zsh_aliases ~/.config/zsh/.zsh_aliases
create_symlink ~/config/zsh/.zsh_variables ~/.config/zsh/.zsh_variables
create_symlink ~/config/zsh/.zsh_path ~/.config/zsh/.zsh_path
create_symlink ~/config/zsh/.zsh_functions ~/.config/zsh/.zsh_functions

#create_symlink ~/config/zsh/.p10k.zsh ~/.p10k.zsh

# Tmux configuration
#create_symlink ~/config/tmux/.tmux.conf ~/.tmux.conf

# Kitty configuration
# create_symlink ~/config/kitty/kitty.conf ~/.config/kitty/kitty.conf

# i3 configuration
# create_symlink ~/config/i3/config ~/.config/i3/config
