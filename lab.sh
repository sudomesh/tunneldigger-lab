#!/bin/bash

tmux new-session -d -s td_lab
tmux rename-window 'TD_LAB'
tmux select-window -t td_lab:0
# Create left column of lab data
tmux split-window -h
tmux send-keys 'watch -cd -n 0.5 -- ip -c addr' 'C-m'
tmux split-window -v
tmux send-keys 'watch -cd -n 0.5 -- netstat -u' 'C-m'
tmux split-window -v
tmux send-keys 'sudo tail -f /var/log/syslog | grep td-client' 'C-m'
# Switch to original column 
tmux select-pane -t 0
tmux send-keys 'echo LAB STARTING IN 10 SECONDS...' 'C-m'
# We could also create a lower pane and leave top pane free...
tmux send-keys 'clear && echo "Lab starting in 10 seconds..." && sleep 10 && echo "...here we go! (^c to exit)" && /vagrant/client.sh' 'C-m'
# Join session. User will be in pane 0.
#   -2 Forces screen-256color
tmux -2 attach-session -t td_lab
