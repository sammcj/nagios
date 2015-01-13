#!/bin/bash -x
#
# Checks that the puppet agent is running and enabled
#
LOCKFILE=/var/lib/puppet/state/agent_disabled.lock

ps auxww | grep -v grep | grep "puppet agent" 1>/dev/null
if (($? > 0)); then
    MESSAGE="Critical: puppet agent process not found!" >&2
    EXIT=2
  elif [[ -e $LOCKFILE ]]; then
    MESSAGE="Puppet agent disabled!" >&1
    EXIT=1
  else
    MESSAGE="Puppet agent enabled and running"
    EXIT=0
fi

echo "$MESSAGE"
exit $EXIT
