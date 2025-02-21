#!/bin/sh

STATE=""
OUTPUT=""
ESC=$(printf "\033")
GREEN_ANSI="$ESC[32m"
RED_ANSI="$ESC[31m"
NC="$ESC[0m"

GREEN_HEX="#3c3"
RED_HEX="#c33"

add_state() {
	[ -z "$STATE" ] && STATE="$1" || STATE="$STATE $1"
}

# Usage:
# add_output <output> [separator]
add_output() {
	local separator=" "
	[ -n "$2" ] && separator="$2"
	[ -z "$OUTPUT" ] && OUTPUT="$1" || OUTPUT="$OUTPUT$separator$1"
}

[ -d /tmp/ffmpeg_recordings ] && [ -f /tmp/ffmpeg_recordings/pid ] && add_state "RECORDING"


for state in $STATE; do
	case "$state" in
		RECORDING) add_output "%{T2}%{F$RED_HEX}󰑋%{F-}%{T-}" ;;
	esac
done

echo "$OUTPUT"
