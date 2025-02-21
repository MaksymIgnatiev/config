#!/bin/sh

ESC=$(printf "\033")
GREEN="$ESC[32m"
NC="$ESC[0m"

print_help() {
	echo "Usage: $green$0$nc <command>"
	echo ${GREEN}COMMAND$NC:
	echo "  brightness <±value|value>        Adjust the brightness by given persentage, or set it. '+' - increase, '-' - decrease, just number - set"
}

get_focused_monitor() {
	i3-msg -t get_workspaces | jq -r ".[] | select(.focused==true).output"
}

# Usage:
# get_backlight_device "monitor_name"
get_backlight_device() {
    local output=$1
    # This mapping might need to be adjusted based on your system
    case $output in
        eDP1) echo "intel_backlight" ;;
        DP1) echo "acpi_video0" ;;
        HDMI-1) echo "acpi_video1" ;;
        *) echo "Unknown" ;;
    esac
}

change_brightness() {
    local value=$1
	local s_value=$(echo "$value" | sed "s/[+\-]//g")
    local output=$(get_focused_monitor)
    local device=$(get_backlight_device "$output")

    [ "$device" = "Unknown" ] && echo "No known backlight device for output $output" && exit 1
	
	echo "$value" | grep "^+" && light -s "sysfs/backlight/$device" -A $s_value && return
	echo "$value" | grep "^-" && light -s "sysfs/backlight/$device" -U $s_value && return
	light -s "sysfs/backlight/$device" -S $s_value && return
}

operate_brightness() {
	local value="$1"
	[ -z "$value" ] && echo "No value provided" && exit 1
	echo "$value" | grep -q "^+[0-9]\+$" || echo "$value" | grep -q "^-[0-9]\+$" || echo "$value" | grep -q "^[0-9]\+$" || {
		echo "Value must be prepended with leading '+', '-' or without for: '+' - increase, '-' - decrease, without sign - set; by certain persentage"
		exit 1
	}

	change_brightness "$value"
}

case "$1" in
    brightness) operate_brightness "$2" ;;
    *) print_help && exit 0 ;;
esac
