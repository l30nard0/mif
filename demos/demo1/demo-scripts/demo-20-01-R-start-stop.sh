#!/bin/bash

ROLE=`hostname`
COMMAND=$1

# directories
DEMOHOME=../${0%/*}

source $DEMOHOME/conf_$ROLE.sh

function start {
  echo "Starting $ROLE"
  ip link set $DEV1 up
  $DEMOHOME/run.sh start $ROLE
}
function stop {
  echo "Stopping $ROLE"
  $DEMOHOME/run.sh stop $ROLE
  ip link set $DEV1 down
}

function reset {
  stop
  ip link set $DEV1 up
  exit 1
}

if [ -n "$COMMAND" ]; then
  eval $COMMAND
  exit
fi

trap on_exit SIGINT
i=1
while [ $i -lt 6 ]; do
  start
  sleep 30
  stop
  sleep 30
  (( i++ ))
done
