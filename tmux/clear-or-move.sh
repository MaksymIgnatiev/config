#!/bin/sh

tmux display-message -p '#{pane_at_left}' | grep -q 1 && tmux select-pane -R || tmux send-keys C-l

