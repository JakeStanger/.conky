import sys
import os

fname = '/home/jake/.conky/trackProgress'

if not os.path.isfile(fname):
	with open(fname, 'a') as f:
		f.write('0')

with open(fname, 'r+') as f:
	progress = f.readline().strip()
	print(int(progress))
	if int(sys.argv[1]) < int(progress) + 1: progress = '0'

	f.truncate(0)
	f.write(progress)
	print(progress)
