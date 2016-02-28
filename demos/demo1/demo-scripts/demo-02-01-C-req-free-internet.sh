#!/bin/bash

# directories
DEMOHOME=$(dirname $(cd $(dirname "$0"); pwd))
REPOROOT=$(dirname $(dirname "$DEMOHOME"))
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo Running: pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://[2001:db8:10::2]/swtrailer.mp4 -P $TMPDIR
$TESTAPPS/pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://[2001:db8:10::2]/swtrailer.mp4 -P $TMPDIR

# or launch in firefox
#$TESTAPPS/pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" firefox http://[2001:db8:10::2]/swtrailer.mp4
