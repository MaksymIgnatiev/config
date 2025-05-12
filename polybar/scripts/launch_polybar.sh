#!/bin/sh

main() {
	type "xrandr" >/dev/null && {
		for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
			MONITOR=$m polybar --reload toph &
		done
	} || polybar --reload toph &
}

main >/dev/null 2>&1
