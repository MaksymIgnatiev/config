#!/bin/sh

# Main method to capture screen
main() {
	# Capture current window focus
	FOCUSED_WIN=$(xdotool getwindowfocus)
	# Launch Flameshot GUI
	flameshot gui
	# Restore focus to the previously focused window
	xdotool windowfocus "$FOCUSED_WIN"
}

# Secondary method to capture screen, if main doesn't work
secondary() {
	maim -s | xclip -selection clipboard -t image/png
}

main >/dev/null 2>&1

# Uncomment if main method doesn't work
# secondary
