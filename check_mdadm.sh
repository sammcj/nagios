#!/bin/bash
#
# Author: Sam McLeod

STATUS=""
EXIT=""

# Get array names
RAID_DEVICES=$(grep ^md /proc/mdstat | awk '{print "/dev/"$1}')

# Get the name of any failed arrays
FAILED_ARRAYS=$(awk '/.*_.*/{print a}{a=$1}' /proc/mdstat)

# Is an array currently recovering, get percentage of recovery
RAID_RECOVER=`grep recovery /proc/mdstat | awk '{print $4}'`

# Check raid status
if [[ $RAID_RECOVER ]]; then
  STATUS="$STATUS WARNING - Recovering : $RAID_RECOVER"
  EXIT=1
elif [[ -z $FAILED_ARRAYS ]]; then
  STATUS="$STATUS OK - Checked $RAID_DEVICES arrays."
  EXIT=0
else
  STATUS="CRITICAL - FAILED RAID ARRAY(S): $FAILED_ARRAYS"
  EXIT=2
fi

# Status and quit
echo $STATUS
exit $EXIT
