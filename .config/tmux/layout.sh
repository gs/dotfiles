#!/usr/bin/env bash
set -euo pipefail

# Rebuild the current window into:
# - left top: nvim
# - left bottom: shell
# - right: pi (focused)
target_pane_id="${1:-}"
current_path="${2:-$HOME}"

if [ -z "$target_pane_id" ]; then
  target_pane_id="$(tmux display-message -p '#{pane_id}')"
fi

# Remove all other panes in this window first so layout is deterministic.
tmux kill-pane -a -t "$target_pane_id"

# Ensure target pane is in the requested path.
tmux send-keys -t "$target_pane_id" "cd ${current_path}" C-m

# Create right pane, then split left side into top/bottom.
right_pane_id="$(tmux split-window -h -p 34 -t "$target_pane_id" -c "$current_path" -P -F '#{pane_id}')"
tmux split-window -v -p 29 -t "$target_pane_id" -c "$current_path" >/dev/null

# Launch tools.
tmux send-keys -t "$target_pane_id" "nvim" C-m
tmux send-keys -t "$right_pane_id" "cd ${current_path}" C-m "opi" C-m
tmux select-pane -t "$right_pane_id"
