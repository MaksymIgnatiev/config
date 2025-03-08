# some arrows...
# '➜ '
# ← ↑ → ↓ ↔ ↕ ↖ ↗ ↘ ↙ ↚ ↛ ↜ ↝ ↞ ↟ ↠ ↡ ↢ ↣ ↤ ↥ ↦ ↧ ↨ ↩ ↪ ↫ ↬ ↭ ↮ ↯ ↰ ↱ ↲ ↳ ↴ ↵ ↶ ↷ ↸ ↹ ↺ ↻ ↼ ↽ ↾ ↿ ⇀ ⇁ ⇂ ⇃ ⇄ ⇅ ⇆ ⇇ ⇈ ⇉ ⇊ ⇋ ⇌ ⇍ ⇎ ⇏ ⇐ ⇑ ⇒ ⇓ ⇔ ⇕ ⇖ ⇗ ⇘ ⇙ ⇚ ⇛ ⇜ ⇝ ⇞ ⇟ ⇠ ⇡ ⇢ ⇣ ⇤ ⇥ ⇦ ⇧ ⇨ ⇩ ⇪
# => <=

bindkey -v # vim my beloved
export KEYTIMEOUT=1

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
unsetopt BEEP PIPE_FAIL

autoload -U colors && colors

ZSH="$HOME/.zsh"

# Where all zsh configuration will be
ZDOTDIR="$HOME/.config/zsh"

HISTFILE="$ZDOTDIR/.zsh_history"
SAVEHIST=32168
HISTSIZE=32168

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
_comp_options+=(globdots)
zmodload zsh/complist

# 'Ctrl + e' to edit current command in editor (i guess not vscode xd)
autoload edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# 'Shift + Tab' to select previous item in menu
bindkey '^[[Z' reverse-menu-complete

# Select in menu with vim keys (place this after compinit)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Prefix-based history search with up/down arrows
bindkey '^[[A' history-search-backward # Up arrow
bindkey '^[[B' history-search-forward  # Down arrow

# Vim alternatives in command mode
bindkey -a 'k' history-search-backward
bindkey -a 'j' history-search-forward

# Inspired by: 
lfcd() {
	tmp=$(mktemp)	
	lf -last-dir-path=$tmp $@
	if [ -f $tmp ]; then
		_dir=$(cat $tmp)
		rm -f $tmp
		[ -d $_dir ] && [ $_dir != `pwd` ] && cd $_dir
	fi
	true
}

secure_eval() {
	[ -z "$1" ] && return 1 || type "$1" >/dev/null 2>&1
}

# 'Ctrl + o' to select a dir with `lf` to cd into it
bindkey -s '^o' 'lfcd\n'

# Load all functions in global view of the shell
source ~/.config/zsh/.zsh_functions

# Path
source ~/.config/zsh/.zsh_path

# Variables
source ~/.config/zsh/.zsh_variables

# Aliases
source ~/.config/zsh/.zsh_aliases

secure_eval zoxide && eval "$(zoxide init zsh --cmd cd)"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

secure_eval pyenv && {
	eval "$(pyenv init --path)"
	eval "$(pyenv init -)"
}

# bun completions
[ -s "/home/arrow_function/.bun/_bun" ] && source "/home/arrow_function/.bun/_bun"

secure_eval fzf && eval "$(fzf --zsh)"

secure_source() { [ -f $1 ] && source $1; }

secure_source "$HOME/.p10k.zsh"
secure_source "$ZSH/powerlevel10k/powerlevel10k.zsh-theme"
secure_source "$ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
secure_source "$ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh"

