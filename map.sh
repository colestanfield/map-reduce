#!/bin/bash

logdir="/matrix/logs"
yesterday=$(date --date='yesterday' '+%Y-%m-%d')
for file in $(find $logdir -type f -name "*access*$yesterday*"); do
    extract="cat $file"
    [[ "$file" =~ ^.*.gz$ ]] && extract="gunzip -c $file"
    count=$($extract | grep -v -e 'GET ".*/server-info.*"' | grep -c -v -e 'GET ".*/server-status.*"')
    hosttype=$(hostname -s | sed 's/[0-9]//g')
    echo "$hosttype $count"
done
