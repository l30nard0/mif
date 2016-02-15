#!/bin/bash

# directories
DEMOHOME=${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

# compile apps
( cd $TESTAPPS && make 1> /dev/null 2> /dev/null)

echo "Running: pvd_list"
$TESTAPPS/pvd_list

echo "Running: pvd_get_by_id f037ea62-ee4f-44e4-825c-16f2f5cc9b3f"
$TESTAPPS/pvd_get_by_id "f037ea62-ee4f-44e4-825c-16f2f5cc9b3f"

echo "Running: pvd_get_by_properties {\"pricing\": \"free\"}"
$TESTAPPS/pvd_get_by_properties "{\"pricing\": \"free\"}"

echo "Running: pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f ip netns identify"
$TESTAPPS/pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f ip netns identify

echo
echo Running: pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f ip a
$TESTAPPS/pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f ip a

echo
echo "Running: pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f cat /etc/netns/mifpvd-2/resolv.conf"
$TESTAPPS/pvd_run f037ea62-ee4f-44e4-825c-16f2f5cc9b3f cat /etc/netns/mifpvd-2/resolv.conf

echo -e "\n"
echo Running: pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://[2001:db8:10::2]
$TESTAPPS/pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://[2001:db8:10::2]

echo -e "\n"
echo Running: pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://www.pvd1.org
$TESTAPPS/pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" wget http://www.pvd1.org

echo -e "\n"
echo Running: pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" ls -al /etc
$TESTAPPS/pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" cat /run/resolvconf/resolv.conf
