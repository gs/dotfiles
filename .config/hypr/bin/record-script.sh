#!/usr/bin/env bash

getdate() {
  date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
  pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2
}
getactivemonitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

mkdir -p "$(xdg-user-dir VIDEOS)"
cd "$(xdg-user-dir VIDEOS)" || exit
if pgrep wf-recorder >/dev/null; then
  hyprctl notify -1 2000 "rgb(ff1ea3)" "Stopped recording" &
  pkill wf-recorder &
else
  hyprctl notify -1 2000 "rgb(ff1ea3)" "Start recording" &
  if [[ "$1" == "--sound" ]]; then
    wf-recorder --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' -t --geometry "$(slurp)" --audio="$(getaudiooutput)" &
    disown
  elif [[ "$1" == "--fullscreen-sound" ]]; then
    wf-recorder -o $(getactivemonitor) --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' -t --audio="$(getaudiooutput)" &
    disown
  elif [[ "$1" == "--fullscreen" ]]; then
    wf-recorder -o $(getactivemonitor) --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' -t &
    disown
  else
    wf-recorder --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' -t --geometry "$(slurp)" &
    disown
  fi
fi
