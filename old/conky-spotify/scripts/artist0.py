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
output = format(json['artist']['#text'].encode('utf-8'))

# make a line break every 38 characters
print re.sub('(.{38})', '\\1 ⏎\n   ', output, 0, re.DOTALL)
