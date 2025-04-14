# Some nice arrows 
# (better with nerd font of font that supports icons and ligatures)
# ➜ ← ↑ → ↓ ↔ ↕ ↖ ↗ ↘ ↙ ↚ ↛ ↜ ↝ ↞ ↟ ↠ ↡ ↢ ↣ ↤ ↥ ↦ 
# ↧ ↨ ↩ ↪ ↫ ↬ ↭ ↮ ↯ ↰ ↱ ↲ ↳ ↴ ↵ ↶ ↷ ↸ ↹ ↺ ↻ ↼ ↽ ↾ 
# ↿ ⇀ ⇁ ⇂ ⇃ ⇄ ⇅ ⇆ ⇇ ⇈ ⇉ ⇊ ⇋ ⇌ ⇍ ⇎ ⇏ ⇐ ⇑ ⇒ ⇓ ⇔ ⇕ ⇖ 
# ⇗ ⇘ ⇙ ⇚ ⇛ ⇜ ⇝ ⇞ ⇟ ⇠ ⇡ ⇢ ⇣ ⇤ ⇥ ⇦ ⇧ ⇨ ⇩ ⇪

# Basic setup ==============================================

# Zsh home directory
ZSH="$HOME/.zsh"

# Where all zsh configuration will be
ZDOTDIR="$HOME/.config/zsh"

# Where history file will be located
HISTFILE="$ZDOTDIR/.zsh_history"
SAVEHIST=32168
HISTSIZE=32168

export KEYTIMEOUT=1


# Enable vi-like mode
bindkey -v


# Setting usefull options ==================================

setopt SHARE_HISTORY           # Share history between all running zsh sessions
setopt INC_APPEND_HISTORY      # Add commands to history immediately
setopt INC_APPEND_HISTORY_TIME # Include timestamp (for better merging)
setopt HIST_EXPIRE_DUPS_FIRST  # Remove duplicates when trimming history
setopt HIST_IGNORE_DUPS        # Ignore duplicate consecutive commands
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicate commands
setopt HIST_IGNORE_SPACE       # Ignore commands starting with a space
setopt HIST_FIND_NO_DUPS       # Avoid duplicate suggestions in search
setopt HIST_REDUCE_BLANKS      # Remove extra spaces from history
setopt HIST_VERIFY             # Don't execute on Up-arrow, just show
setopt APPEND_HISTORY  

setopt autocd extendedglob nomatch menucomplete interactive_comments  


# Unsetting annoying options ===============================

unsetopt beep pipefail


# Loading modules and enabling core functionality ==========

# Answer that helped to resolve issue with prefix search in history
# https://superuser.com/questions/1357131/zsh-in-vi-mode-but-using-arrow-keys-to-search-history

autoload -U colors && colors
autoload -Uz compinit && compinit
autoload -Uz history-search-end
autoload edit-command-line

zstyle ':completion:*' menu select
_comp_options+=(globdots)
zmodload zsh/complist

zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

zle -N edit-command-line


# Usefull keybinds =========================================

# 'Ctrl + e' to edit current command in $EDITOR editor
bindkey '^e' edit-command-line

# 'Shift + Tab' to select previous item in menu
bindkey '^[[Z' reverse-menu-complete

# Select in menu with vim keys (place this after compinit)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Vim-like arrow up/down to search history (with prefix)
bindkey -a 'k' history-beginning-search-backward-end
bindkey -a 'j' history-beginning-search-forward-end

# Up/Down arrow to cycle through history 
# based on typed in prefix: vi-like command mode
bindkey -M vicmd '^[[A' history-beginning-search-backward-end \
                 '^[OA' history-beginning-search-backward-end \
                 '^[[B' history-beginning-search-forward-end \
                 '^[OB' history-beginning-search-forward-end

# Up/Down arrow to cycle through history 
# based on typed in prefix: vi-like insert mode
bindkey -M viins '^[[A' history-beginning-search-backward-end \
                 '^[OA' history-beginning-search-backward-end \
                 '^[[B' history-beginning-search-forward-end \
                 '^[OB' history-beginning-search-forward-end


# Inspired by: https://www.youtube.com/watch?v=eLEo4OQ-cuQ
lfcd() {
	local tmp=$(mktemp)
	lf -last-dir-path=$tmp "$@"
	if [ -f "$tmp" ]; then
		local _dir=$(cat $tmp)
		rm -f "$tmp"
		[ -d "$_dir" ] && [ "$_dir" != "`pwd`" ] && cd "$_dir"
	fi
	true
}

# 'Ctrl + o' to select a dir with `lf` to cd into it
bindkey -s '^o' 'lfcd\n'


# Helper functions =========================================

# Checks if the given file exists
exists() { [ -f "$1" -a -s "$1" ] ; }

# Usage:
# secure_eval executable_name && eval "$(evaluation code)"
secure_eval() { [ -z "$1" ] && return 1 || type "$1" >/dev/null 2>&1 ; }

# Usage:
# secure_source path/to/source/file
secure_source() { exists "$1" && \. "$1" ; }


# Custom config ============================================

# Load all functions into the global scope of the shell
secure_source "$HOME/.config/zsh/.zsh_functions"

# Populate the $PATH env "variable"
secure_source "$HOME/.config/zsh/.zsh_path"

# Set "variables"
secure_source "$HOME/.config/zsh/.zsh_variables"

# Set "aliases"
secure_source "$HOME/.config/zsh/.zsh_aliases"


# Evaluation ===============================================

# zoxide initialization and completions (alias: cd)
secure_eval zoxide && eval "$(zoxide init zsh --cmd cd)"

# fzf initialization and completions
secure_eval fzf && eval "$(fzf --zsh)"

# uv completions
secure_eval uv && eval "$(uv generate-shell-completion zsh)"


# Sourcing =================================================

# nvm + nvm completions
secure_source "$NVM_DIR/nvm.sh"

# bun completions
secure_source "$HOME/.bun/_bun"

# ghcup setup
secure_source "/home/arrow_function/.ghcup/env"

# plugins
secure_source "$HOME/.p10k.zsh"
secure_source "$ZSH/powerlevel10k/powerlevel10k.zsh-theme"
secure_source "$ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
secure_source "$ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh"
