#!/bin/sh

FOCUSED_MONITOR=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).output')

FOCUSED_DEVICE=$(light -L | grep "$FOCUSED_MONITOR" | awk '{print $1}')

[ -z "$FOCUSED_DEVICE" ] && FOCUSED_DEVICE=$(light -L | head -n 1 | awk '{print $1}')

# "brightness"
section="$1"

argument="$2"

[ "$section" = "brightness" ] && {
    echo "$argument" | grep -E "\+[0-9]+$" && {
        light -s "$FOCUSED_DEVICE" -A "$2"
        notify-send "Brightness ($FOCUSED_MONITOR): $(light -s "$FOCUSED_DEVICE" -G)%"
    } || echo "$2" | grep -E "-[0-9]+$" && {
        light -s "$FOCUSED_DEVICE" -U "$2"
        notify-send "Brightness ($FOCUSED_MONITOR): $(light -s "$FOCUSED_DEVICE" -G)%"
	}
}

# Listing
# sysfs/backlight/intel_backlight
# sysfs/backlight/asus_screenpad
# sysfs/backlight/auto
# sysfs/leds/input51::kana
# sysfs/leds/input9::capslock
# sysfs/leds/input51::capslock
# sysfs/leds/phy0-led
# sysfs/leds/input51::numlock
# sysfs/leds/input51::scrolllock
# sysfs/leds/input51::compose
# sysfs/leds/asus::kbd_backlight
# sysfs/leds/input9::numlock
# sysfs/leds/input9::scrolllock
# util/test/dryrun

