#!/bin/bash
# Simple Nagios check to monitor MySQL Query Per Seconds (QPS) with performance data output
# Author : Dutiko (Pierre D.)
# v1 - 2021-10-15 : Original write

MYSQL_BIN=/usr/bin/mysql
BC_BIN=/usr/bin/bc

usage()
{
	echo "Usage: $0 -H hostname -u username -p xxxx -w warning -c critical"
	exit 3
}
if [ $# -ne 10 ] ; then
	usage
fi

while getopts ":H:u:p:w:c:" opt ; do
	case $opt in
		H)
			hostname=$OPTARG
			;;
		u)
			username=$OPTARG
			;;
		p)
			password=$OPTARG
			;;
		w)
			warn=$OPTARG
			;;
		c)
			crit=$OPTARG
			;;
		*)
			usage
			;;
	esac
done

TMP_FILENAME=/tmp/check_mysql_qps.dat

if [ -f /tmp/check_mysql_qps.dat ]
then
	PAST_TIME=$(grep time /tmp/check_mysql_qps.dat | awk -F'=' {'print $2'})
	PAST_QUERIES=$(grep queries /tmp/check_mysql_qps.dat | awk -F'=' {'print $2'})
else
	PAST_TIME=0
	PAST_QUERIES=0
fi

QUERIES=$(${MYSQL_BIN} -h${hostname} -u${username} -p${password} -Ns -e "show status like 'Queries'" | awk {'print $2'})
TIME=$(date '+%s')

echo "time=${TIME}
queries=${QUERIES}" > /tmp/check_mysql_qps.dat

if [[ $PAST_TIME -eq 0 ]] ; then echo "OK - initializing" ; exit 0 ; fi

N_SEC=$((${TIME} - ${PAST_TIME}))
N_QUERIES=$((${QUERIES} - ${PAST_QUERIES}))
QUERY_RATE=$((${N_QUERIES}/${N_SEC}))

if [[ ${QUERY_RATE} -ge ${crit} ]] ; then echo -n "CRITICAL current Query Per Seconds : ${QUERY_RATE}"
elif [[ ${QUERY_RATE} -ge ${warn} ]] ; then echo -n "WARNING current Query Per Seconds : ${QUERY_RATE}"
else echo -n "OK current Query Per Seconds : ${QUERY_RATE}"
fi
#echo "|'QPS'=${QUERY_RATE};${warn};${crit};;"
echo "|'QPS'=${QUERY_RATE}"

