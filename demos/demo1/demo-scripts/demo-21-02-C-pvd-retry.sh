#!/bin/bash

# directories
DEMOHOME=$(dirname $(cd $(dirname "$0"); pwd))
REPOROOT=$(dirname $(dirname "$DEMOHOME"))
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo Running: ./pvd_echo_client_signal 2001:db8:10::2 20000
$TESTAPPS/./pvd_echo_client_signal 2001:db8:10::2 20000
