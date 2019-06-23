import shutil
import requests
from os.path import isfile, exists
from os import makedirs
from sys import argv
from urllib.parse import quote

base_path = '/home/jake/.cache/conky/data/thumbs'

if not exists(base_path):
    makedirs(base_path)

path = base_path + '/%s - %s' % (argv[1], argv[2])
if not isfile(path):
    url = "https://music.jakestanger.com/music/image/%s/%s/150" % (quote(argv[1]), quote(argv[2]))
    # print(url)
    r = requests.get(url, stream=True)
    if r.status_code == 200:
        with open(path, 'wb') as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
