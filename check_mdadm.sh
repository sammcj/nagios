#!/bin/bash
#
# Author: Sam McLeod

STATUS=""
EXIT=""

# Get all array names
function RAID_DEVICES {
  grep ^md /proc/mdstat | awk '{print "/dev/"$1}'
}

# Get the name of any failed arrays
function FAILED_ARRAYS {
  awk '/.*_.*/{print a}{a=$1}' /proc/mdstat
}

# Get the name of any arrays recovering
function RAID_RECOVER {
  awk '/recovery/{print $0}' /proc/mdstat
}

# Get the name of any arrays resync
function RAID_RESYNC {
  awk '/resync/ && !/DELAYED/{print $0}' /proc/mdstat
}

# The number of failed arrays
NUM_FAILED=$(FAILED_ARRAYS | wc -l)

# The number of recovering arrays
NUM_RECOVER=$(RAID_RECOVER | wc -l)

# The number of recovering arrays
NUM_RESYNC=$(RAID_RESYNC | wc -l)

# If the number of failed arrays doesn't match the number that are recoverying, return CRITICAL
if [[ $NUM_RECOVER -ne $NUM_FAILED ]]; then
  STATUS="CRITICAL - FAILED RAID ARRAY(S): $(FAILED_ARRAYS)"
  EXIT=2

# If the only failed arrays are recovering, return WARNING
elif [[ $NUM_RECOVER -gt 0 ]]; then
  STATUS="$STATUS WARNING - Recovering : $(RAID_RECOVER)"
  EXIT=1

# If the only failed arrays are recovering, return WARNING
elif [[ $NUM_RESYNC -gt 0 ]]; then
  STATUS="$STATUS WARNING - Resyncing : $(RAID_RESYNC)"
  EXIT=1

# If there are no failed arrays return OK
elif [[ -z $FAILED_ARRAYS ]]; then
  STATUS="$STATUS OK - Checked $(RAID_DEVICES)."
  EXIT=0
fi

# Status and quit
echo $STATUS
exit $EXIT
