#!/bin/bash
#
# Usage:
# ./check_postgres_rep_status.sh db_ip_1 db_ip_2
# (i.e. add possible IPs for slave)
#
# Author: Sam McLeod

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

## Master (p_) and Slave (s_) DB Server Information
dbip1=$1
dbip2=$2
dbip3=$3
dbip4=$4
export psql=/usr/bin/psql

repstatus=$($psql -A -t -c "select client_addr, state, sent_location, write_location, flush_location, replay_location from pg_stat_replication;")

echo $repstatus | grep "$dbip1\|$dbip\|$dbip3\|$dbip4"

if [[ $? -ne 0 ]]; then
    echo "CRITICAL: Replication broken or disabled!"
    exit $STATE_CRITICAL
else
    echo "OK: Replication stream detected: ($repstatus)"
    exit $STATE_OK
fi
