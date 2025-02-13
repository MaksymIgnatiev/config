#!/bin/sh

GREEN_HEX="#3c3"
LIGHTGREEN_HEX="#ad1"
YELLOW_HEX="#ee0"
ORANGE_HEX="#fa4"
DARKORANGE_HEX="#e80"
RED_HEX="#c33"

GREEN_ANSI="\033[32m"
LIGHTGREEN_ANSI="\033[38;5;154m"
YELLOW_ANSI="\033[33m"
ORANGE_ANSI="\033[38;2;230;128;0m"
DARKORANGE_ANSI="\033[38;5;202m"
RED_ANSI="\033[31m"
NC="\033[0m"

RAM_ICON=" "
SWAP_ICON=" "

USE_HEX='false'
POLYBAR='false'

# %{F%c}%s%{F-}
# %c = color
# %s = string
POLYBAR_TEMPLATE="%{F%c}%s%{F-}"

[ "$1" = "polybar" ] && {
	USE_HEX='true'
	POLYBAR='true'
} || [ "$1" = "hex" ] && USE_HEX='true'

STATE_FILE="/tmp/polybar_memory_display"

[ ! -f "$STATE_FILE" ] && echo "MEM" > "$STATE_FILE"

# "MEM" | "MEM_SWAP"
STATE=$(cat "$STATE_FILE")

[ "$2" = "toggle" ] && {
	[ "$STATE" = "MEM" ] && {
		echo "MEM_SWAP" > "$STATE_FILE"
		STATE="MEM_SWAP"
	} || {
		echo "MEM" > "$STATE_FILE"
		STATE="MEM"
	}
}


# Take one snapshot, e.g:
#                total        used        free      shared  buff/cache   available
# Mem:           15789        4052       10334         636        2371       11736
# Swap:           8192          88        8104
MEM_INFO=$(free -m)

# And use this snapshot
RAM_USED=$(echo   "$MEM_INFO" | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(echo  "$MEM_INFO" | awk '/Mem:/ {print $2}')
SWAP_USED=$(echo  "$MEM_INFO" | awk '/Swap:/ {print $3}')
SWAP_TOTAL=$(echo "$MEM_INFO" | awk '/Swap:/ {print $2}')

RAM_USED_P=$((RAM_USED * 100 / RAM_TOTAL))
SWAP_USED_P=$((SWAP_USED * 100 / SWAP_TOTAL))

# Format the given memory in Mb and return a `mem mem_sufix`
format_mem() {
	mem="$1"
	[ $mem -lt 1024 ] && echo "$mem Mb" && return
	echo "$(echo | awk "{printf \"%.2f\n\", $mem / 1024}") Gb" && return
}

# echo "RAM used %: $RAM_USED_P, SWAP used %: $SWAP_USED_P"

# Returns the color based on the percentage passed in (0-100)
get_color() {
	usage=$1
	usage=$((usage % 100))

	# 20-49% - most used part
	case "$usage" in
		[0-9]|1[0-9])        echo "$([ $USE_HEX = 'true' ] && echo $GREEN_HEX      || echo "$GREEN_ANSI"     )" ;;
		[234][0-9])          echo "$([ $USE_HEX = 'true' ] && echo $LIGHTGREEN_HEX || echo "$LIGHTGREEN_ANSI")" ;;
		5[0-9]|6[0-4])       echo "$([ $USE_HEX = 'true' ] && echo $YELLOW_HEX     || echo "$YELLOW_ANSI"    )" ;;
		6[5-9]|7[0-9])       echo "$([ $USE_HEX = 'true' ] && echo $ORANGE_HEX     || echo "$ORANGE_ANSI"    )" ;;
		8[0-9])              echo "$([ $USE_HEX = 'true' ] && echo $DARKORANGE_HEX || echo "$DARKORANGE_ANSI")" ;;
		*)                   echo "$([ $USE_HEX = 'true' ] && echo $RED_HEX        || echo "$RED_ANSI"       )" ;;
	esac
}

color_str() {
	usage="$1"
	str="$2"
	color=$(get_color $usage)
	[ $USE_HEX = 'true' ] && {
		[ $POLYBAR = 'true' ] && echo $POLYBAR_TEMPLATE | sed -e "s/%c/$color/g" -e "s/%s/$str/g" || echo "$color$str"
	} || echo "$(get_color $usage)$str$NC"
}

[ "$STATE" = "MEM" ] &&	{
	echo "$(color_str $RAM_USED_P "$RAM_ICON $(format_mem $RAM_USED)")"
} || {
	echo "$(color_str $RAM_USED_P "$RAM_ICON $(format_mem $RAM_USED)")" "$(color_str $SWAP_USED_P "$SWAP_ICON$(format_mem $SWAP_USED)")"
}

