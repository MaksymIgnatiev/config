#!/bin/sh

# Handle polybar at any time:
# if exists - try to restart them with 'polybar-msg' utility; if errors - kill all instances, and relaunch
# if not exists - just launch

launch() { ~/.config/polybar/scripts/launch_polybar.sh ; }

pgrep polybar && killall -9 polybar

# for some reason following line doesn't work as expected
# polybar-msg cmd restart >/dev/null 2>&1 || { killall -9 polybar ; false ; }

launch
