# frozen_string_literal: true

# Minimal Prompt - Oh My Zsh Custom Plugin
# Shows: foldername (branch|time) ❯
#
# Time format: 45s, 10m, 2h, 5d, 3w (rounded integers)
#
# Installation:
#   1. Copy to ~/.oh-my-zsh/custom/plugins/minimal-prompt/
#   2. Add to plugins in .zshrc: plugins=(... minimal-prompt)

# Enable prompt substitution for dynamic content
setopt PROMPT_SUBST

# Format time since commit into nice rounded integers
function _minimal_prompt_time_since() {
  local commit_ts="$1"
  local now_ts=$(date +%s)
  local diff=$((now_ts - commit_ts))

  if [[ $diff -lt 60 ]]; then
    echo "${diff}s"                                           # seconds
  elif [[ $diff -lt 3600 ]]; then
    echo "$(( (diff + 30) / 60 ))m"                         # minutes
  elif [[ $diff -lt 86400 ]]; then
    echo "$(( (diff + 1800) / 3600 ))h"                     # hours
  elif [[ $diff -lt 604800 ]]; then
    echo "$(( (diff + 43200) / 86400 ))d"                   # days
  else
    echo "$(( (diff + 302400) / 604800 ))w"                 # weeks
  fi
}

# Build the prompt
function _minimal_prompt_render() {
  local dir_name="${PWD##*/}"
  [[ -z "$dir_name" ]] && dir_name="/"

  # Cyan folder name
  local prompt="%F{cyan}${dir_name}%f"

  # Check for git
  local git_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  if [[ -n "$git_branch" ]]; then
    local time_suffix=""

    # Get time since last commit
    local commit_ts=$(git log -1 --format=%ct 2>/dev/null)
    if [[ -n "$commit_ts" ]]; then
      time_suffix="$(_minimal_prompt_time_since "$commit_ts")"
    fi

    # Yellow branch + optional time
    if [[ -n "$time_suffix" ]]; then
      prompt="${prompt} %F{yellow}(${git_branch}|${time_suffix})%f"
    else
      prompt="${prompt} %F{yellow}(${git_branch})%f"
    fi
  fi

  # Green arrow
  echo "${prompt} %F{green}❯%f "
}

# Set the prompt
PROMPT='$(_minimal_prompt_render)'
