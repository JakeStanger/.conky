import os, sys
hostname = sys.argv[1]
response = os.system("ping -c 1 " + hostname + " > /dev/null 2>&1")

#and then check the response...
if response == 0:
  print('up')
else:
  print('dn')
