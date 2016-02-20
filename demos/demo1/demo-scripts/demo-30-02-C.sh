#!/bin/bash

# Run only on Client   !!!
# Run after demo-30-01 !!!

ROLE=`hostname`
if [ $ROLE == "client" ]; then ROLE="C"; fi
if [ "$ROLE" != "C" ]; then
  echo "Run on client only!"
  exit 1
fi
COMMAND=$1

DEV0=eno16777736 # device that should be turned off during tests
DEV1=eno33554984 # first device used in tests

DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps
PVDMAN=$REPOROOT/pvdman
TMPLDIR=$DEMOHOME/templates

function start {
  ${0%/*}/demo-30-01-C+S2.sh create
  mkdir -p $TMPDIR
  if [ ! -f /etc/dbus-1/system.d/dbus-pvd-man.conf ]; then
    cp $TMPLDIR/dbus-pvd-man.conf /etc/dbus-1/system.d/
  fi
  if [ -n "$DEV1" ]; then
    python3 $PVDMAN/main.py -i $DEV1 --demo 30 > $TMPDIR/pvdman.log 2>&1  &
  else
    python3 $PVDMAN/main.py --demo 30 > $TMPDIR/pvdman.log 2>&1  &
  fi
  echo "mif-pvd man started (waiting 5 sec for pvds to be set)"
  sleep 5

  # run some apps

  #$TESTAPPS/pvd_list
  #f037ea62-ee4f-44e4-825c-16f2f5cc9b3e (R2)
  #317a088c-ab67-43a3-bcf0-23c26f623a2d (S2)

  $TESTAPPS/pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3e wget://[fd02::01] -P $TMPDIR
  cat $TMPDIR/index.html
  rm $TMPDIR/index.html
  $TESTAPPS/pvd_run 317a088c-ab67-43a3-bcf0-23c26f623a2d wget://[fd02::01] -P $TMPDIR
  cat $TMPDIR/index.html
  rm $TMPDIR/index.html
}

function stop {
  killall -SIGINT python3 && echo "mif-pvd man stopped"
  if [ $? == "0" ]; then
    sleep 3
    ps -A | grep python3 > /dev/null
    if [ $? == "0" ]; then
      killall -SIGINT python3 && echo "mif-pvd man killed"
    fi
  fi
  py3clean $PVDMAN
  ${0%/*}/demo-30-01-C+S2.sh delete
}

eval $COMMAND
