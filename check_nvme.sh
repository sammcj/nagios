#!/bin/bash
#
# Simple Nagios check for nvme using nvme-cli
# Original Author: Sam McLeod https://smcleod.net
# https://github.com/sammcj/nagios/blob/master/check_nvme.sh
# Maintainer : Pierre D. - https://dutiko.com/
#
# v3 : change detection method
# v2.3 : check if script is runned as root/sudo, exit with unknown error if not
# v2.2 : add check to detect if nvme disks are detected, exit with unknown error if not
# v2.1 : add checks to detect if nvme-cli is present, exit with unknown error if not
# v1 : Original
#
# Requirements:
# nvme-cli - git clone https://github.com/linux-nvme/nvme-cli
#
# Usage:
# ./check_nvme.sh

# Am I root ?
if [ $(id -u) -ne 0 ] ; then echo "UNKNOWN: please run as root or with sudo" ; exit 3 ; fi

DISKS=$(lsblk -e 11,253 -dn -o NAME | grep nvme)
CRIT=false
MESSAGE=""

command -v nvme >/dev/null 2>&1 || { echo >&2 "UNKNOWN: nvme-cli not found ; please install it" ; exit 3; }
if [ -z "$DISKS" ] ; then echo "UNKNOWN: no nvme disks found"; exit 3; fi

for DISK in $DISKS ; do
  # Check for critical_warning
  CRITICAL_WARNING=$(nvme smart-log /dev/$DISK | grep "critical_warning" | awk '{print $3}')
  if [ $CRITICAL_WARNING -ne 0 ]; then
    CRIT=true
    MESSAGE="$MESSAGE $DISK has $CRITICAL_WARNING critical warning "
  fi

  # Check media_errors
  MEDIA_ERRORS=$(nvme smart-log /dev/$DISK | grep "media_errors" | awk '{print $3}')
  if [ $MEDIA_ERRORS -ne 0 ]; then
    CRIT=true
    MESSAGE="$MESSAGE $DISK has $MEDIA_ERRORS media errors "
  fi

  # Check num_err_log_entries
  $(nvme smart-log /dev/$DISK | awk 'FNR == 16 && $3 != 0 {exit 1}')
  NUM_ERR_LOG_ENTRIES=$(nvme smart-log /dev/$DISK | grep ""num_err_log_entries | awk '{print $3}')
  if [ $NUM_ERR_LOG_ENTRIES -ne 0 ]; then
    CRIT=true
    MESSAGE="$MESSAGE $DISK has $NUM_ERR_LOG_ENTRIES errors logged "
  fi
done

if [ $CRIT = "true" ]; then
  echo "CRITICAL: $MESSAGE"
  exit 2
else
  echo "OK $(echo $DISKS | tr -d '\n')"
  exit 0
fi
