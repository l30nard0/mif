#!/bin/bash

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make > /dev/null 2>&1 )

# fixme: use pvd-id from implicit pvds
# bbffa8f5-0db3-5e6b-b585-c2ebd1a92af5
# eec252d9-6dcf-d320-1fb4-3a98cb26f9fe

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo Running: multi_pvd_echo_client \
acc0370c-3f30-3519-6265-61aba9d9c3bd 2001:db8:10::2 20000 \
2ca7aae2-3d8b-aa20-ea0b-bf62ff78f1a0 2001:db8:20::2 20000
$TESTAPPS/multi_pvd_echo_client \
acc0370c-3f30-3519-6265-61aba9d9c3bd 2001:db8:10::2 20000 \
2ca7aae2-3d8b-aa20-ea0b-bf62ff78f1a0 2001:db8:20::2 20000

