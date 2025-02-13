export ZDOTDIR="$HOME/.config/zsh"

# Start X server if it's 1'st TTY
[ -z $DISPLAY ] && [ $XDG_VTNR -eq 1 ] && startx
