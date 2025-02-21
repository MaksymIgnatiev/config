#!/bin/sh

id=$(xinput list | awk '/Touchpad/' | grep -o "id=[[:digit:]]\+" | cut -d'=' -f2)

[ -z "$id" ] || echo $id | grep "\n" && exit

xinput set-prop $id "libinput Natural Scrolling Enabled" 1
xinput set-prop $id "libinput Tapping Enabled" 1
