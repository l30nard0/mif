#!/bin/bash

# run this script on router R1 before next script on client

# directories
DEMOHOME=../${0%/*}

i=1

while [ $i -lt 4 ]; do
  echo "Starting R1"
  sudo $DEMOHOME/run.sh start R1
  sleep 15
  echo "Stopping R1"
  sudo $DEMOHOME/run.sh stop R1
  sleep 15
  (( i++ ))
done