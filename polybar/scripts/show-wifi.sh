#!/bin/sh

# Arguments:
# ./show-wifi.sh [polybar] [toggle]
# If argument needs to be absent - use `-` symbol


LIGHTBLUE_HEX="#0cf"
GREEN_HEX="#0c4"
RED_HEX="#F00"

LIGHTBLUE_ANSI="\033[38;5;117m"
GREEN_ANSI="\033[38;5;118m"
RED_ANSI="\033[31m"
NC="\033[0m"

WIFI_ICON=" "
NOWIFI_ICON="󰤮 "
IP_ICON="󰩟 "

USE_HEX="false" # by default use ANSI to output to terminal

[ "$1" = "polybar" ] && USE_HEX="true"

STATE_FILE="/tmp/polybar_wlan_state"

[ ! -f "$STATE_FILE" ] && echo "0" > "$STATE_FILE"

# 0 | 1
# 0 = SSID
# 1 = SSID + Local IP
STATE=$(cat "$STATE_FILE")

[ "$2" = "toggle" ] && {
    STATE=$(( (STATE + 1) % 2 ))
    echo "$STATE" > "$STATE_FILE"
}

hex() { [ $USE_HEX = "true" ] && return $? ; }

SSID=$(iwgetid -r)
IP=$(ip -4 addr show wlan0 | awk '/inet / {print $2}' | cut -d'/' -f1)

[ -z "$SSID" ] && {
	hex && echo "%{F$RED_HEX}$NOWIFI_ICON%{F-}" || echo "$RED_ANSI$NOWIFI_ICON$NC"
} || {
	[ "$STATE" -eq 0 ] && {
		hex && echo "%{F$LIGHTBLUE_HEX}$WIFI_ICON $SSID%{F-}" || echo "$LIGHTBLUE_ANSI$WIFI_ICON$NC $LIGHTBLUE_ANSI$SSID$NC"
	} || {
		hex && echo "%{F$LIGHTBLUE_HEX}$WIFI_ICON $SSID %{F$GREEN_HEX}$IP_ICON$IP%{F-}" || echo "$LIGHTBLUE_ANSI$WIFI_ICON$NC $LIGHTBLUE_ANSI$SSID$NC $GREEN_ANSI$IP_ICON$NC$GREEN_ANSI$IP$NC"
	}
}
