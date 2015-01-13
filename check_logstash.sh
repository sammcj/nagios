#!/bin/bash

ES_SERVER=$1
LS_SERVER=$2

DATE=$(date +%Y.%m.%d)
DATE2=$(date --date="yesterday" +%Y.%m.%d)

INDEX="logstash-$DATE"
INDEX2="logstash-$DATE2"

CHECK_STRING="check_logstash_$(date +%N)"

echo $CHECK_STRING > /dev/tcp/$LS_SERVER/5553

for i in 1 2 3 4 5
do
  sleep 5

  curl -XGET http://$ES_SERVER/$INDEX2/_search?q=$CHECK_STRING | grep -q $CHECK_STRING
  IN_YESTERDAY=$?
  curl -XGET http://$ES_SERVER/$INDEX/_search?q=$CHECK_STRING | grep -q $CHECK_STRING
  IN_TODAY=$?
  if [ $IN_YESTERDAY -gt 0 ] && [ $IN_TODAY -gt 0 ]; then
    MESSAGE="CRITICAL: Logstash not logging to Elasticsearch!" >&2
    EXIT=2
  else
    MESSAGE="OK: Logstash is logging as expected"
    EXIT=0
    break
  fi
done

echo "$MESSAGE"
exit $EXIT
