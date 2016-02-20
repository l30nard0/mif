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
  /sbin/ip -6 route add $REMOTE_IP via $GW

  # create tunnel
  ip -6 tunnel add $TUNNEL mode ip6ip6 local $LOCAL_IP remote $REMOTE_IP dev $DEV1
  ip link set dev $TUNNEL up

  ip address add $TUNNEL_IP/64 dev $TUNNEL
  if [ $ROLE == "S2" ]; then
    source demo-30-01-S2-radvd.conf > $TMPDIR/radvd.conf
    /usr/local/sbin/radvd -d 5 -n -C $TMPDIR/radvd.conf -m logfile -l $TMPDIR/radvd.log &
    echo "radvd started"
  fi
}
function delete {
  if [ $ROLE == "S2" ]; then killall radvd; fi
  ip address del $TUNNEL_IP/64 dev $TUNNEL
  ip -6 tunnel del $TUNNEL mode ip6ip6 local $LOCAL_IP remote $REMOTE_IP dev $DEV1
  /sbin/ip -6 route del $REMOTE_IP via $GW
  /sbin/ip -6 addr del "$LOCAL_IP/64" dev $IFACE
}

# directories
DEMOHOME=../${0%/*}
REPOROOT=$DEMOHOME/../..
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps

if [ $ROLE == "C" ]; then
  LOCAL_IP="2001:db8:2::200"
  REMOTE_IP="2001:db8:20::201"
  TUNNEL_IP="fd02::200"
  GW="2001:db8:2::1"
else
  LOCAL_IP="2001:db8:20::201"
  REMOTE_IP="2001:db8:2::200"
  TUNNEL_IP="fd02::1"
  GW="2001:db8:20::1"
fi

source $DEMOHOME/conf_$ROLE.sh

IFACE=$DEV1
TUNNEL=tnlvpnx

eval $COMMAND
