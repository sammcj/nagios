#!/bin/bash
#
# Usage:
# ./check_postgres_replication.sh int-docker-pg-vip int-docker-pg-standby mycoolapp
#
# Author: Sam McLeod

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

CONFIG_FILE=/usr/local/etc/vipchange.cfg

function usage () {
	cat <<-EOF

	Usage:
	    ${0##*/} [--config config_file] [--help]
	        --config ... path to config file, default: $CONFIG_FILE

	    Example:
	        ${0##*/} --config $CONFIG_FILE
	EOF
}

GETOPT_PARSED=$(getopt -o hvc: --long help,verbose,config: -- "$@" )
if [[ $? != 0 ]] ; then "aborting..." >&2; usage ; exit 1 ; fi

eval set -- "$GETOPT_PARSED"
while true ; do
    case "$1" in
        -h|--help) usage; exit 1 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -c|--config) CONFIG_FILE=$2 ; shift 2 ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

if [[ -f "$CONFIG_FILE" ]]; then
    . "$CONFIG_FILE"
fi


## Master (p_) and Slave (s_) DB Server Information
p_host=${POSTGRES_ACTIVE_IP:-$1}
p_port=5432
s_host=${POSTGRES_STANDBY_IP:-$2}
s_port=5432
database=${3:-postgres}

## Limits
critical_limit=83886080 # 5 * 16MB, size of 5 WAL files
warning_limit=16777216 # 16 MB, size of 1 WAL file

function bytes() {
    bytes=$1
    if [[ $bytes -gt 2097152 ]]; then
        echo "$(( $bytes / 1048576 )) MiB"
	return
    elif [[ $bytes -gt 2048 ]]; then
        echo "$(( $bytes / 1024 )) KB"
	return
    else
        echo "$bytes B"
        return
    fi
}

# Human-readable format:
critical_limit_M=$( bytes ${critical_limit} )
warning_limit_M=$( bytes ${warning_limit} )

# These 3 values form a bit of a 'race-condition' as they are sampled at different times
# Typically, the replay > slave > master, so we sample them in this order
replay_xlog_loc=$(psql --no-psqlrc -U replicator -h $s_host -p $s_port -A -t -c "SELECT pg_xlog_location_diff(pg_last_xlog_replay_location(), '0/0') AS replay" $database)
slave_xlog_loc=$(psql --no-psqlrc -U replicator  -h $s_host -p $s_port -A -t -c "SELECT pg_xlog_location_diff(pg_last_xlog_receive_location(), '0/0') AS receive" $database)
master_xlog_loc=$(psql --no-psqlrc -U replicator -h $p_host -p $p_port -A -t -c "SELECT pg_xlog_location_diff(pg_current_xlog_location(), '0/0') AS offset" $database)
replay_lag_s=$(psql --no-psqlrc -U replicator -h $s_host -p $s_port -A -t -c "SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0.0 ELSE EXTRACT(EPOCH FROM now() - pg_last_xact_replay_timestamp()) END" $database)

# pg_last_xact_replay_timestamp() is the timestamp of the last transaction replayed - it does not represent a 'lag' at all
# in normal operation, it represents the time since 'something happened' on the secondary
#replay_timediff=$(psql --no-psqlrc -U replicator -h $s_host -p $s_port -A -t -c "SELECT -EXTRACT(EPOCH FROM (pg_last_xact_replay_timestamp() - NOW() ))" $database)

if [[ "$replay_lag_s" = '' ]]; then
    # This is normal if nothing has been replayed yet - set to U for performance data
    replay_lag_s=U
fi

if [[ $master_xlog_loc -eq '' || $slave_xlog_loc -eq '' || $replay_xlog_loc -eq '' ]]; then
    echo "CRITICAL: Stream has no value to compare (is replication configured or connectivity problem?)"
    exit $STATE_CRITICAL
fi

master_replay_lag=$( bc <<< "$master_xlog_loc-$replay_xlog_loc" )
master_slave_lag=$( bc <<< "$master_xlog_loc-$slave_xlog_loc" )
PERFDATA="replay_bytes=${master_xlog_loc}c stream_lag=$master_slave_lag replay_lag=$master_replay_lag lag_s=${replay_lag_s}s"

master_slave_lag_M=$( bytes $( bc <<< "($master_xlog_loc-$slave_xlog_loc)" ) )
master_replay_lag_M=$( bytes $( bc <<< "($master_xlog_loc-$replay_xlog_loc)" ) )

if [[ "$master_slave_lag" -gt "$critical_limit" ]]; then
    MESSAGE="Stream beyond critical limit ($master_slave_lag_M > $critical_limit_M )"
    EXIT_CODE=$STATE_CRITICAL
elif [[ "$master_slave_lag" -gt "$warning_limit" ]]; then
    MESSAGE="Stream beyond warning limit ($master_slave_lag_M > $warning_limit_M )"
    EXIT_CODE=$STATE_WARNING
elif [[ "$master_replay_lag" -gt "$warning_limit" ]]; then
    MESSAGE="Replay beyond warning limit ($master_replay_lag_M > $warning_limit_M )"
    EXIT_CODE=$STATE_WARNING
elif [[ "$master_replay_lag" -gt 0 || "$master_slave_lag" -gt 0 ]]; then
    MESSAGE="Lagging within limits: Stream lag: $master_slave_lag_M, Replay lag: $master_replay_lag_M"
    EXIT_CODE=$STATE_OK
elif [[ $master_xlog_loc -eq $slave_xlog_loc && $master_xlog_loc -eq $replay_xlog_loc && $slave_xlog_loc -eq $replay_xlog_loc ]] ; then
    MESSAGE="No lag, MASTER:$master_xlog_loc Slave:$slave_xlog_loc Replay:$replay_xlog_loc"
    EXIT_CODE=$STATE_OK
else
    # Unreachable under normal conditions
    MESSAGE=" MASTER:$master_xlog_loc Slave:$slave_xlog_loc Replay:$replay_xlog_loc Master-slave lag: $master_slave_lag, Master-replay lag: $master_replay_lag"
    EXIT_CODE=3
fi


case "$EXIT_CODE" in
    0) MESSAGE="OK: $MESSAGE";;
    1) MESSAGE="WARNING: $MESSAGE";;
    2) MESSAGE="CRITICAL: $MESSAGE";;
    *) MESSAGE="UNKNOWN: $MESSAGE";;
esac

if [[ "$replay_lag_s" != U ]]; then
    MESSAGE="$MESSAGE,  Replay lag: ${replay_lag_s}s"
fi
echo "${MESSAGE}|${PERFDATA}"
exit $EXIT_CODE
