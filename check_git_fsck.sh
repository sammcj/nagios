#!/bin/bash
# Checks for git repo corruption

if [[ "$#" -ne "1" ]] ; then
  echo "Usage: check_git_fsck.sh <repodir>"
  exit 3
fi

GIT_OBJECT_DIRECTORY=$1

cd $GIT_OBJECT_DIRECTORY
git fsck --full --no-progress --no-dangling

if [ $? -eq 0 ]; then
    echo "OK: git fsck of ${GIT_OBJECT_DIRECTORY} ok"; exit 0;
else
  echo "CRITICAL: git repo corruption detected in ${GIT_OBJECT_DIRECTORY}"
  exit 2
fi
