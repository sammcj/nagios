#!/bin/bash

numsocks=`lsof 2>&1 |grep docker.sock|wc -l`

if [ $numsocks -gt 20000 ]; then
	echo "CRITICAL - $numsocks sockets"
	exit 2
fi

if [ $numsocks -gt 5000 ]; then
	echo "WARNING - $numsocks sockets"
	exit 1
fi

echo "OK - $numsocks socket(s)"
exit 0
