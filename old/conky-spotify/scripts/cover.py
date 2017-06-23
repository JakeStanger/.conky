#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import requests
import re

url = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=Grandad_Sadbags&api_key=a51061959945be9b70d4af56b4b55d79&format=json&limit=1"
feed = requests.get(url);
if not feed.status_code == requests.codes.ok:
	print "Error fetching last.fm feed"
	exit()
json = feed.json()['recenttracks']['track'][0]
output = format(json['image'][3]['#text'].encode('utf-8'))

with open('/home/jake/.conky/conky-spotify/scripts/cover.png', 'wb') as handle:
        response = requests.get(output, stream=True)

        if not response.ok:
            print response

        for block in response.iter_content(1024):
            if not block:
                break

            handle.write(block)
