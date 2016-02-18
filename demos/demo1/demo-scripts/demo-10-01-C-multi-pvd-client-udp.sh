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
bbffa8f5-0db3-5e6b-b585-c2ebd1a92af5 2001:db8:10::2 20000 \
eec252d9-6dcf-d320-1fb4-3a98cb26f9fe 2001:db8:20::2 20000
$TESTAPPS/multi_pvd_echo_client \
bbffa8f5-0db3-5e6b-b585-c2ebd1a92af5 2001:db8:10::2 20000 \
eec252d9-6dcf-d320-1fb4-3a98cb26f9fe 2001:db8:20::2 20000

#echo Running: multi_pvd_echo_client \
#f037ea62-ee4f-44e4-825c-16f2f5cc9b3f 2001:db8:10::2 20000 \
#f037ea62-ee4f-44e4-825c-16f2f5cc9b3e 2001:db8:20::2 20000
#$TESTAPPS/multi_pvd_echo_client \
#f037ea62-ee4f-44e4-825c-16f2f5cc9b3f 2001:db8:10::2 20000 \
#f037ea62-ee4f-44e4-825c-16f2f5cc9b3e 2001:db8:20::2 20000
