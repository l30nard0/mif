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
  /sbin/ip -6 addr add "$LOCAL_IP/64" dev $IFACE
  /sbin/ip -6 route add $REMOTE_IP via $GW
  ip -6 tunnel add $TUNNEL mode ip6gre local $LOCAL_IP remote $REMOTE_IP dev $DEV1
  if [ "$ROLE" == "C" ]; then
    ip netns add VPNTEST
    ip link set dev $TUNNEL netns VPNTEST
    ip netns exec VPNTEST ip address add $TUNNEL_IP/64 dev $TUNNEL
    ip netns exec VPNTEST ip link set dev $TUNNEL up
  else
    ip address add $TUNNEL_IP/64 dev $TUNNEL
    ip link set dev $TUNNEL up
    # source demo-30-01-S2-radvd.conf > $TMPDIR/radvd.conf
    # /usr/local/sbin/radvd -d 5 -n -C $TMPDIR/radvd.conf -m logfile -l $TMPDIR/radvd.log &
    # echo "radvd started"
  fi
}
function delete {
  if [ "$ROLE" == "C" ]; then
    #ip netns exec VPNTEST ip link del $TUNNEL
    ip netns del VPNTEST
  else
    ip -6 tunnel del $TUNNEL
    # killall radvd
  fi

  ip -6 route del $REMOTE_IP via $GW
  ip -6 addr del "$LOCAL_IP/64" dev $IFACE
}

# directories
DEMOHOME=$(dirname $(cd $(dirname "$0"); pwd))
REPOROOT=$(dirname $(dirname "$DEMOHOME"))
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
