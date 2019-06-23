#!/bin/zsh
token=$(cat /home/jake/.config/conky/mpd/token)

track=$1
artist=$2
if [ -z "$1" ]; then
  track=$(mpc -f %title% | head -n 1)
  artist=$(mpc -f %artist% | head -n 1)
fi

if [ -z "$track" ]; then
  echo "Missing track name"
  exit 1
fi

if [ -z "$artist" ]; then
  echo "Missing artist name"
  exit 1
fi

# track_sanitised$(echo {} | fx 'encodeURIComponent("$track")')

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

track_sanitised=$(rawurlencode "$track")

track_js=$(echo $track | sed s/\'/"\\\'"/)

curl -s -H "Accept: application/json" -H "Authorization: Basic $token" "https://m.jstanger.dev/music/search/$track_sanitised" | \
  fx "this.tracks.filter(t => new RegExp(decodeURIComponent('$track_sanitised'), 'i').test(t.name) && t.artist_name == '$artist')[0].id" | read id;
  
if [ -z "$id" ]; then
  echo "[Lyrics not found]"
  exit 1
fi

curl -s -H "Accept: application/json" -H "Authorization: Basic $token" "https://m.jstanger.dev/music/track/$id/lyrics"