#!/usr/bin/python
### Check if redis cluster is in a correct status
### AUTHOR: Pierre DOLIDON

import subprocess
import sys
import os

command = "redis-cli cluster info | grep cluster_state"
p = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
output, err = p.communicate()
state = output.split(':')[1].rstrip()

if state == 'ok':
    print "OK : Cluster is in OK state"
else:
    print "CRITICAL : Cluster is not in optimal state"

