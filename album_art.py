from urllib.request import urlretrieve
from os.path import isfile
from sys import argv
from urllib.parse import quote
base_path = '/home/jake/.conky'
path = base_path + '/data/thumbs/%s - %s' % (argv[1], argv[2])
if not isfile(path):
    url = "http://music.jakestanger.com/image/%s/%s/150" % (quote(argv[1]), quote(argv[2]))
    print(url)
    urlretrieve(url, path)
