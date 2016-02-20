#!/bin/bash

function Usage () {
  echo "Usage: sudo $0 create|delete"
  echo "  Create/delete tunnel between Client and S2"
  exit 1
}

ROLE=`hostname`
if [ $ROLE == "client" ]; then ROLE="C"; fi
if [ "$1" != "create" -a "$1" != "delete" ]; then Usage; fi
if [ "$ROLE" != "C" -a "$ROLE" != "S2" ]; then Usage; fi

COMMAND=$1

function create {
  # add ip address to interface $IFACE
  /sbin/ip -6 addr add "$LOCAL_IP/64" dev $IFACE

  # create tunnel
  ip -6 tunnel add $TUNNEL mode ip6ip6 local $LOCAL_IP remote $REMOTE_IP dev $DEV1
  ip link set dev $TUNNEL up

  if [ $ROLE == "S2" ]; then
    ip address add fd02::2/64 dev $TUNNEL
#    start_radvd
  fi
}
function delete {
  ip -6 tunnel del $TUNNEL mode ip6ip6 local $LOCAL_IP remote $REMOTE_IP dev $DEV1
  /sbin/ip -6 addr del "$LOCAL_IP/64" dev $IFACE
  if [ $ROLE == "S2" ]; then
    ip address del fd02::2/64 dev $TUNNEL
#    stop radvd
  fi
}

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

if [ $ROLE == "C" ]; then
  LOCAL_IP="2001:db8:2::200"
  REMOTE_IP="2001:db8:20::201"
else
  LOCAL_IP="2001:db8:20::201"
  REMOTE_IP="2001:db8:2::200"
fi

source $DEMOHOME/conf_$ROLE.sh

IFACE=$DEV1
TUNNEL=tunnel1

eval $COMMAND
