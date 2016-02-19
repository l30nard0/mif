#!/bin/bash

ROLE=`hostname`
COMMAND=$1

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

source $DEMOHOME/conf_$ROLE.sh

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

#echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#echo Running: ./pvd_echo_client 2001:db8:10::2 20000
#$TESTAPPS/pvd_echo_client 2001:db8:10::2 20000

IFACE=$DEV1
LOCAL_IP="2001:db8:2::2"
REMOTE_IP="2001:db8:20::2"


