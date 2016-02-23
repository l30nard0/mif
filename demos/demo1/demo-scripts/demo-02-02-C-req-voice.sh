#!/bin/bash

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo Running: pvd_prop_run "{\"type\": \"voice\"}" wget http://[fd02::1]/swtheme.mp3 -P $TMPDIR
$TESTAPPS/pvd_prop_run "{\"type\": \"voice\"}" wget http://[fd02::1]/swtheme.mp3 -P $TMPDIR

# or launch in firefox
#$TESTAPPS/pvd_prop_run "{\"type\": \"voice\"}" firefox http://[2001:db8:20::2]/swtheme.mp3
