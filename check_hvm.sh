#!/bin/bash
# check if kernel version is 3.1X and alerts if HVM is not set
#
#set -o nounset

#set -o errexit

kernel=`/usr/bin/dpkg -l | grep linux-image-3\.[1-9][0-9]`


if [[ "$?" == "0" ]] ; then
	grep -q HVM /usr/lib/nagios/plugins/hvm
	if [[ "$?" != "0" ]] ; then
		echo "WARNING - kernel > 3.2 but HVM not set, System will not boot"
		exit 1
	else 
		echo "OK - kernel > 3.2 and HVM set"	
		exit 0
	fi
fi	

echo "OK - kernel =< 3.2"
exit 0
