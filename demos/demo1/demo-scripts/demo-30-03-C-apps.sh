#!/bin/bash

# start on client after 30-02 !!!

DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TESTAPPS=$REPOROOT/testapps

$TESTAPPS/pvd_list
#f037ea62-ee4f-44e4-825c-16f2f5cc9b3e (R2)
#317a088c-ab67-43a3-bcf0-23c26f623a2d (S2)

$TESTAPPS/pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3e wget -q -O - http://[fd02::01]
$TESTAPPS/pvd_run 317a088c-ab67-43a3-bcf0-23c26f623a2d wget -q -O - http://[fd02::01]
