from plexapi.server import PlexServer
from urllib.request import urlretrieve
from os.path import isfile
from time import time
import traceback

BASEPATH = '/home/jake/.conky'

baseurl = 'http://plex.lan:32400'
token = ''
with open("/home/jake/.conky/token", 'r') as f: token = f.readline().strip()
plex = PlexServer(baseurl, token)


def writeData(name, value):
    print(name, ":", value)
    with open(BASEPATH + '/data/' + name, 'w') as f:
        f.write(str(value))


def readData(name):
    with open(BASEPATH + '/data/' + name, 'r') as f:
        return f.read().strip()


for session in plex.sessions():
    if session.players[0].title == 'JakeDesktop':
        try:
            prevTrack = readData('track')
            if prevTrack != session.title:
                path = BASEPATH + '/data/thumbs/' + session.parentTitle
                if not isfile(path):
                    thumb = session.thumb or session.parentThumb
                    if not thumb:
                        thumb = session.grandparentThumb

                    if thumb:
                        thumb = thumb[1:]

                        url = "http://music.jakestanger.com/image/%s/100" % thumb
                        urlretrieve(url, path)

                writeData('track', session.title)
                writeData('album', session.parentTitle)
                writeData('artist', session.grandparentTitle)
                if session.players[0].state == 'playing':
                    writeData('startTime', time())

            writeData('paused', not session.players[0].state == "playing")
            writeData('duration', session.duration)

        except:
            traceback.print_exc()
            pass
if len(plex.sessions()) == 0:
    with open(BASEPATH + '/data/track', 'w') as f:
        f.write('')
    with open(BASEPATH + '/data/album', 'w') as f:
        f.write('')
    with open(BASEPATH + '/data/artist', 'w') as f:
        f.write('')
    with open(BASEPATH + '/data/paused', 'w') as f:
        f.write('True')
    with open(BASEPATH + '/data/duration', 'w') as f:
        f.write('0')
