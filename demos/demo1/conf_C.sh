#!/bin/bash

# assuming: DEV0 - general internet access - not to be used during test
#           DEV1, DEV2 - for tests, have assigned link-local IPv6 addresses
DEV0=eno16777736 # device that should be turned off during tests
DEV1=eno33554984 # first device used in tests

PVDMAN=$REPOROOT/pvdman

function client_start {
  if [ ! -f /etc/dbus-1/system.d/dbus-pvd-man.conf ]; then
    cp $TMPLDIR/dbus-pvd-man.conf /etc/dbus-1/system.d/
  fi
  if [ -n "$DEV1" ]; then
    python3 $PVDMAN/main.py -i $DEV1 > $TMPDIR/pvdman.log 2>&1  &
  else
    python3 $PVDMAN/main.py > $TMPDIR/pvdman.log 2>&1  &
  fi
  echo "mif-pvd man started"
  echo "start pvd-aware programs now"
}

function client_stop {
  killall -SIGINT python3 && echo "mif-pvd man stopped"
  if [ $? == "0" ]; then
    sleep 3
    ps -A | grep python3 > /dev/null
    if [ $? == "0" ]; then
      killall -SIGINT python3 && echo "mif-pvd man killed"
    fi
  fi
  py3clean $PVDMAN
}

function client_clean {
  #client_stop
  rm -f /etc/dbus-1/system.d/dbus-pvd-man.conf
}
