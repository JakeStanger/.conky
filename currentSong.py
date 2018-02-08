from plexapi.server import PlexServer
from urllib.request import urlretrieve
from os.path import isfile

baseurl = 'http://plex.lan:32400'
token = ''
with open("/home/jake/.conky/token", 'r') as f: token = f.readline().strip()
plex = PlexServer(baseurl, token)


for session in plex.sessions():
	if session.players[0].title == 'JakeDesktop':
		try:
			path = '/home/jake/.conky/data/thumbs/' + session.parentTitle
			if not isfile(path):
				url = 'http://music.jakestanger.com/getImage?width=90&height=90&thumb-id=' + session.thumb
				urlretrieve(url, path)

			with open("/home/jake/.conky/data/track", 'w') as f:
				f.write(session.title)
			with open("/home/jake/.conky/data/album", 'w') as f:
				f.write(session.parentTitle)
			with open("/home/jake/.conky/data/artist", 'w') as f:
				f.write(session.grandparentTitle)
			with open("/home/jake/.conky/data/paused", 'w') as f:
				f.write(str(not session.players[0].state == "playing"))
		except:
			pass

if len(plex.sessions()) == 0:
	with open("/home/jake/.conky/data/track", 'w') as f:
		f.write("")
	with open("/home/jake/.conky/data/album", 'w') as f:
		f.write("")
	with open("/home/jake/.conky/data/artist", 'w') as f:
		f.write("")
	with open("/home/jake/.conky/data/paused", 'w') as f:
		f.write("True")
