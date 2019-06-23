#!/usr/bin/env node

track = process.argv[2];

if (!track) {
  console.log("Missing track");
  process.exit(1);
}

artist = process.argv[3];

if (!artist) {
  console.log("Missing artist");
  process.exit(1);
}

const fetch = require("node-fetch");
const fs = require("fs");


const filePath = `/home/jake/.lyrics/${artist.replace(/\//g, "-")} - ${track.replace(/\//g, "-")}.txt`;

if(fs.existsSync(filePath)) {
  console.log(fs.readFileSync(filePath).toString());
  process.exit(0);
}

const token = fs.readFileSync("/home/jake/.config/conky/mpd/token").toString();

fetch(`https://m.jstanger.dev/music/search/${encodeURIComponent(track)}`, {
  headers: {
    Accept: "application/json",
    Authorization: `Basic ${token}`
  }
})
  .then(res => res.json())
  .then(results => {
    const searchTrack = results.tracks.filter(t => t.name == track && t.artist_name == artist)[0];
    if (searchTrack) {
      const id = searchTrack.id;
      fetch(`https://m.jstanger.dev/music/track/${id}/lyrics`, {
        headers: {
          Accept: "application/json",
          Authorization: `Basic ${token}`
        }
      })
        .then(res => res.text())
        .then(lyrics => {
          console.log(lyrics);
          fs.writeFileSync(filePath, lyrics);
        });
    }
  });
