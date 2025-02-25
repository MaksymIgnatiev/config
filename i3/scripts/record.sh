#!/bin/sh

# Inspired by: https://www.youtube.com/@BreadOnPenguins: https://www.youtube.com/watch?v=7yHYH7I4o9s

# Path to save all recordings
SAVE_PATH="$HOME/Videos/ffmpeg/"

[ -d "$SAVE_PATH" ] || mkdir -p "$SAVE_PATH"

# %Y = full year (e.g. 2025)
# %m = month (e.g. 06)
# %d = day (e.g. 12)
# %H = 24h hour (e.g. 13)
# %M = minute (e.g. 45)
# %S = seconds (e.g. 06)
FILENAME_FORMAT="%d.%m.%Y_%H:%M:%S.mp4"

# Some nice ANSI escape codes to color the output
ESC=$(printf "\033")
GREEN="$ESC[32m"
RED="$ESC[31m"
# No Color (clear all)
NC="$ESC[0m"


REQUIRED_TOOLS="ffmpeg slop"
REQUIRED_MISSING_TOOLS=""

# Check for missing tools
for tool in $REQUIRED_TOOLS; do
	type $tool >/dev/null 2>&1 || REQUIRED_MISSING_TOOLS="$REQUIRED_MISSING_TOOLS $tool"
done

# If some required tools are missing - list them
[ -n "$REQUIRED_MISSING_TOOLS" ] && {
	echo "Some required tools are missing:"
	for fool in $REQUIRED_MISSING_TOOLS; do echo "  - $GREEN$tool$NC"; done
	echo "Install them to continue"
	exit 0
}

print_help() {
	echo "Usage ${0##*/} $(is_tty && echo "<filename> ")[options...]"
	echo
	echo "${GREEN}Filename$NC is only required when running from interactive shell (e.g. bash/zsh)"
	echo
	echo "${GREEN}OPTIONS$NC:"
	echo "  -a              Record screen with audio from default microphone (not yet implemented!)"
	echo
	echo "All recordings will be saved to the $GREEN$SAVE_PATH$NC directory"
	echo "If running from non-interactive shell (e.g. i3 mapping)  - name of the file will be defined using this pattern: $GREEN$FILENAME_FORMAT$NC"
	echo "If running from interactive shell (e.g. bash/zsh/shell script) - name of the file will be user defined with provided filename"

}

# Is running inside tty (interactive shell or not)
is_tty() { env | grep -q "^WINDOWID=" ; }

ext_doesnt_exist() { echo "${RED}ffmpeg doesn't support '$ext' extension$NC" && exit 0 ; }

# Test if this extension is valid
test_extension() { ffmpeg -muxers 2>&1 | awk '{print $2}' | grep -qw "$1" || ext_doesnt_exist ; }

# Send signal to polybar to update the bar
send_polybar_signal() { type polybar-msg >/dev/null 2>&1 && polybar-msg action '#extra_info.hook.0' >/dev/null 2>&1 ; }

# Start the recording
record() {
	# Print help message if filename is missing (if running from interactive shell)
	is_tty && [ -z "$1" ] && print_help && exit 0

	if is_tty; then
		# Test that given filename is valid
		echo "$1" | grep -q "^\.\.\?$" && echo "File name is a directory ($1)" && exit 0
		! echo "$1" | grep -q "^[a-zA-Z0-9\_\.\-]\+$" && echo "File name doesn't contain any valid name" && exit 0
		! echo "$1" | grep -q "\.[a-zA-Z0-9]\+$" && echo "File name doesn't contain any extension" && exit 0

		# Get file extension
		local ext=$(echo "$1" | sed 's/^.*\.//')

		test_extension "$ext"

		FILENAME="$1"
	else FILENAME="$(date "+$FILENAME_FORMAT")" ; fi

	# Get rectangular area coordinates to record
	local format=$(slop -f '%x %y %w %h')

	# If something went wrong (e.g. canceled)
	[ "$format" = "" ] && exit 0

	# Create variables from given values
	local f=$(mktemp)
	echo $format > $f
	read -r X Y W H < "$f"
	rm -f "$f"
	
	# Make sure that ffmpeg temporary directory is available
	mkdir -p /tmp/ffmpeg_recordings

	# Resolve full path
	local full_path="$SAVE_PATH$FILENAME"

	is_tty && echo "${GREEN}Recording to: $full_path$NC"

	# Start the recording in the background
	ffmpeg -y -f x11grab -video_size "${W}x${H}" -i "$DISPLAY+$X,$Y" -framerate 60 -c:v libx264 -crf 28 -preset ultrafast "$full_path"  >/dev/null 2>&1 &
	
	# Capture the last job PID and send it to the recording status file
	echo "$!" > /tmp/ffmpeg_recordings/pid

	# Send full file path to the recording status file
	echo "$full_path" > /tmp/ffmpeg_recordings/filename

	send_polybar_signal
}

# End the recording ffmpeg process and delete recording status file
remove_status() { kill $(cat /tmp/ffmpeg_recordings/pid) && rm /tmp/ffmpeg_recordings/pid ; }

# End recording
end() {
	remove_status >/dev/null 2>&1
	local filename=$(cat /tmp/ffmpeg_recordings/filename)
	local valid_filename=true

	rm /tmp/ffmpeg_recordings/filename >/dev/null 2>&1

	[ -z "$filename" ] && valid_filename=false
	is_tty && {
		[ "$valid_filename" = "true" ] && \
		echo "Recording saved to: $GREEN$filename$NC" || \
		echo "${RED}Unable to get filename to save the file$NC"
	} || {
		[ "$valid_filename" = "true" ] && \
		notify-send -t 8000 "Screen Recording" "Recording saved to: <span color='#0c0'><b>$filename</b></span>" || \
		notify-send -t 8000 "Screen Recording" "<span color='red'><b>Unable to get filename to save the file</b></span>"
	}
	send_polybar_signal
}


{
	[ -f /tmp/ffmpeg_recordings/pid ] && [ -f /tmp/ffmpeg_recordings/filename ] && end "$@" && exit

	# If something fails, try to stop the process and cleanup the files
	(
		[ -f /tmp/ffmpeg_recordings/pid ] && kill $(cat /tmp/ffmpeg_recordings/pid) && rm /tmp/ffmpeg_recordings/pid
		[ -f /tmp/ffmpeg_recordings/filename ] && rm /tmp/ffmpeg_recordings/filename
	) >/dev/null 2>&1

	send_polybar_signal
	
	false
} || record "$@"
