# Where all config live
export ZDOTDIR="$HOME/.config/zsh"

# Start X server if it's 1'st TTY
# Note! Multiple checks for SSH and Termux
[ -z $DISPLAY ] && [ -n $XDG_VTNRa ] && [ ${XDG_VTNR:-0} -eq 1 ] && startx
