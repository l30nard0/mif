#!/bin/bash

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

echo -e "\n"
echo Running: pvd_prop_run "{\"type\": \"voip\"}" wget http://[2001:db8:20::2]/swtheme.mp3 -P $TMPDIR
$TESTAPPS/pvd_prop_run "{\"type\": \"voip\"}" wget http://[2001:db8:20::2]/swtheme.mp3 -P $TMPDIR

# or launch in firefox
#$TESTAPPS/pvd_prop_run "{\"type\": \"voip\"}" firefox http://[2001:db8:20::2]/swtheme.mp3
