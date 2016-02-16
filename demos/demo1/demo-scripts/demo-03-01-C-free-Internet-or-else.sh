#!/bin/bash

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

# test for "internet" and "free"
echo -e "\n"
echo Running: $TESTAPPS/pvd_get_by_properties "{\"type\":\"internet\",\"pricing\":\"free\"}"
$TESTAPPS/pvd_get_by_properties "{\"type\":\"internet\",\"pricing\":\"free\"}" > /dev/null
if [ $? == 0 ]; then
  echo "Got free internet: watching movie"
  # such pvd exists; run test in it
  $TESTAPPS/pvd_prop_run "{\"type\":\"internet\",\"pricing\":\"free\"}" \
  firefox http://[2001:db8:10::2]/swtrailer.mp4  > /dev/null 2>&1
else
  # no free internet! is at least internet available?
  $TESTAPPS/pvd_get_by_properties "{\"type\":\"internet\"}" > /dev/null
  if [ $? == 0 ]; then
    echo "Got internet (not free): listening music"
    # pvd with internet exist; run something else in it
    $TESTAPPS/pvd_prop_run {\"type\":\"internet\"} \
    firefox http://[2001:db8:20::2]/swtheme.mp3  > /dev/null 2>&1
  else
    echo "No internet connection available! Aborting."
    exit 1
  fi
fi