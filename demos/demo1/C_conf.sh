#!/bin/bash

# assuming: DEV0 - general internet access - not to be used during test
#           DEV1, DEV2 - for tests, have assigned link-local IPv6 addresses
DEV0=eno16777736 # device that should be turned off during tests
DEV1=eno33554984 # first device used in tests

PVDMAN=$REPOROOT/pvdman

function client_start {
  if [ ! -f /etc/dbus-1/system.d/dbus-pvd-man.conf ]; then
    cp dbus-pvd-man.conf /etc/dbus-1/system.d/
  fi
  if [ -n "$DEV1" ]; then
    python3 $PVDMAN/main.py -i $DEV1 2>$TMPDIR/pvdman-error.log 1> $TMPDIR/pvd-man.log &
  else
    python3 $PVDMAN/main.py 2>$TMPDIR/pvdman-error.log 1> $TMPDIR/pvd-man.log &
  fi
  echo "mif-pvd man started"
  echo "start pvd-aware programs now"
}

function client_stop {
  killall -SIGINT python3 && echo "mif-pvd man stopped"
  py3clean $PVDMAN
}

function client_clean {
  stop_client
  rm -f /etc/dbus-1/system.d/dbus-pvd-man.conf
}
