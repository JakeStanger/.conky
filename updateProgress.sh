progress=$(cat trackProgress)

if [ $1 -gt $progress ]; then
	progress=$((progress+1))
else
	progress=0
fi

echo $progress > trackProgress
echo $progress
