#!/bin/bash

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo Running: sudo ./pvd_echo_client 2001:db8:10::2 20000
$TESTAPPS/sudo ./pvd_echo_client 2001:db8:10::2 20000
