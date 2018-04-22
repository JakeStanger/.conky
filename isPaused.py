from plexapi.server import PlexServer
baseurl = 'http://plex.lan:32400'
token = ''
with open("/home/jake/.conky/token", 'r') as f: token = f.readline().strip()
plex = PlexServer(baseurl, token)

for session in plex.sessions():
	if session.username == 'JakeStanger':
		print(not session.player.state == "playing")
