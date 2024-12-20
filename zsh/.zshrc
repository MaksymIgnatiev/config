# some arrows...
# '➜ '
# ← ↑ → ↓ ↔ ↕ ↖ ↗ ↘ ↙ ↚ ↛ ↜ ↝ ↞ ↟ ↠ ↡ ↢ ↣ ↤ ↥ ↦ ↧ ↨ ↩ ↪ ↫ ↬ ↭ ↮ ↯ ↰ ↱ ↲ ↳ ↴ ↵ ↶ ↷ ↸ ↹ ↺ ↻ ↼ ↽ ↾ ↿ ⇀ ⇁ ⇂ ⇃ ⇄ ⇅ ⇆ ⇇ ⇈ ⇉ ⇊ ⇋ ⇌ ⇍ ⇎ ⇏ ⇐ ⇑ ⇒ ⇓ ⇔ ⇕ ⇖ ⇗ ⇘ ⇙ ⇚ ⇛ ⇜ ⇝ ⇞ ⇟ ⇠ ⇡ ⇢ ⇣ ⇤ ⇥ ⇦ ⇧ ⇨ ⇩ ⇪
# => <=

bindkey -v # vim my beloved
export KEYTIMEOUT=1

setopt autocd extendedglob nomatch menucomplete interactive_comments hist_ignore_all_dups 
setopt append_history inc_append_history share_history
setopt hist_ignore_dups hist_ignore_all_dups hist_reduce_blanks
unsetopt BEEP

autoload -U colors && colors

ZSH="$HOME/.zsh"

HISTFILE="$HOME/.zsh_history"
SAVEHIST=10000
HISTSIZE=32168

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
# zmodload zsh/compinit # need fix: failed to load module `zsh/compinit': /usr/lib/zsh/5.9/zsh/compinit.so: cannot open shared object file: No such file or directory
_comp_options+=(globdots)

# 'Ctrl + e' to edit current command in editor (i guess not vscode xd)
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line

# 'Shift + Tab' to select previous item in menu
bindkey '^[[1;2Z' reverse-menu-complete

# need fix: no such keymap `menuselect'
# select in menu with vim keys (place this after compinit)
# bindkey -M menuselect 'h' vi-backward-char
# bindkey -M menuselect 'j' vi-down-line-or-history
# bindkey -M menuselect 'k' vi-up-line-or-history
# bindkey -M menuselect 'l' vi-forward-char

# prefix-based history search with up/down arrows
bindkey '^[[A' history-search-backward # Up arrow
bindkey '^[[B' history-search-forward  # Down arrow
# vim alternatives in command mode
bindkey -a 'k' history-search-backward
bindkey -a 'j' history-search-forward

# select in menu with vim keys
# bindkey -M menuselect 'h' vi-backward-char
# bindkey -M menuselect 'j' vi-down-line-or-history
# bindkey -M menuselect 'k' vi-up-line-or-history
# bindkey -M menuselect 'l' vi-forward-char


lfcd() {
	tmp=$(mktemp)	
	lf -last-dir-path=$tmp $@
	if [ -f $tmp ]; then
		_dir=$(cat $tmp)
		rm -f $tmp
		[ -d $_dir ] && [ $_dir != `pwd` ] && cd $_dir
	fi
}
# 'Ctrl + o' to select a dir with `lf` to cd into it
bindkey -s '^o' 'lfcd\n'




# Load all functions in global view of shell
source ~/.config/zsh/.zsh_functions

# export PATH="$HOME/.pyenv/bin:$PATH"
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init - zsh)"

# Path
source ~/.config/zsh/.zsh_path

# Variables
source ~/.config/zsh/.zsh_variables

# Aliases
source ~/.config/zsh/.zsh_aliases

eval "$(zoxide init zsh --cmd cd)"

# source /usr/share/nvm/init-nvm.sh

# bun completions
[ -s "/home/arrow_function/.bun/_bun" ] && source "/home/arrow_function/.bun/_bun"

eval  "$(fzf --zsh)"

secure_source() { [ -f $1 ] && source $1; }

secure_source "$HOME/.p10k.zsh"
secure_source "$ZSH/powerlevel10k/powerlevel10k.zsh-theme"
secure_source "$ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
secure_source "$ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh"
