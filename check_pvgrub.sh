#!/bin/bash
# check if any physical drive is NOT present in /boot/grub/device.map
#
#

for devdisk in `cat /proc/partitions | awk '/[sv]d[a-z]$/{print $4}'` ; do
	grep -q $devdisk /boot/grub/device.map
	if [[ $? != '0' ]] ; then
			echo "WARNING - $devdisk is missing in /boot/grub/device.map, Server will not boot"
		exit 1
	fi
done

echo "OK - all devices present in /boot/grub/device.map"
exit 0
