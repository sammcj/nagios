#!/bin/bash

# check_redmine_queue.sh
# Sam McLeod 2015
# Alerts when there are (unassigned) tickets of a certain priority in a project queue and if present returns the names of the tickets
#
# Example:
# ./check_redmine_queue.sh <API Key> <Project ID> <Issue priority to monitor> <Redmine URL> <exit code>
# ./check_redmine_queue.sh 12345abc12345abc 1 5 https://redmine.office.infoxchange.net.au 1
# ./check_redmine_queue.sh 12345abc12345abc 1 6 https://redmine.office.infoxchange.net.au 2

API_KEY=$1
PROJECT_ID=$2
PRIORITY_ID=$3
REDMINE_URL=$4
EXIT_CODE=$5

TICKET_INFO=$(curl -s -H "Content-Type: application/json" -H "X-Redmine-API-Key: ${API_KEY}" ${REDMINE_URL}/issues.json\?project_id=${PROJECT_ID}\&priority_id=${PRIORITY_ID})_

echo $TICKET_INFO | grep -q "\"total_count\":0"

if [ $? -ne 0 ]
then
  echo "%s" "$0:\", ..." $TICKET_INFO | grep -Po '"subject":.*?[^\\],'| sed -e 's/"subject":/ /g' | sed 's/\"//g' | tr -d '\n'
  exit $EXIT_CODE
else
  exit 0
fi
