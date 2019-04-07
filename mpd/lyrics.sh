#!/bin/zsh
token=$(cat /home/jake/.config/conky/mpd/token)

track=$1
if [ -z "$1" ]; then
  track=$(mpc -f %title% | head -n 1)
fi

if [ -z "$track" ]; then
  exit 1
fi

track_sanitised=$(echo $track | sed s/\'/%27/)
track_js=$(echo $track | sed s/\'/"\\\'"/)
curl -s -H "Accept: application/json" -H "Authorization: Basic $token" "https://m.jstanger.dev/music/search/$track_sanitised" | \
  fx "this.tracks.filter(t => t.name == '$track_js')[0].id" | read id; \
  curl -s -H "Accept: application/json" -H "Authorization: Basic $token" "https://m.jstanger.dev/music/track/$id/lyrics"

