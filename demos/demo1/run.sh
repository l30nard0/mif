#!/bin/bash

Usage () {
  echo "Usage: sudo $0 start|stop C|R1|R2|S1|S2"
  exit
}
if [ "$1" != "start" -a "$1" != "stop" -a "$1" != "clean" ]; then Usage; fi
if [ "$2" != "C" -a "$2" != "R1" -a "$2" != "R2" \
     -a "$2" != "S1" -a "$2" != "S2" ]; then Usage; fi

COMMAND=$1
ROLE=$2

# directories
DEMOHOME=${0%/*}
REPOROOT=$DEMOHOME/../..
PVDMAN=$REPOROOT/pvdman
TMPDIR=$DEMOHOME/__mif_cache__
HTTPDPROG=apache2
HTTPDCONFDIR=/etc/apache2/sites-enabled #where to store info for web server
HTTPDHTML=/var/www/html
HTTPDPVD=/var/www/html/_pvd_info_
# it is assumed that web server is already configured
# and serves documents from: $HTTPDHTML
RADVD=/usr/local/sbin/radvd
TESTAPPS=$REPOROOT/testapps


function start {
  mkdir -p $TMPDIR

  # disable other connections (NetworkManager)
  if [ -n "$DEV0" ]; then
    nmcli device disconnect $DEV0
  fi

  if [ "$ROLE" = "C" ]; then
    # C - client specific code
    if [ ! -f /etc/dbus-1/system.d/dbus-pvd-man.conf ]; then
      cp dbus-pvd-man.conf /etc/dbus-1/system.d/
    fi
    if [ -n "$DEV1" ]; then
      python3 $PVDMAN/main.py -i $DEV1 2>$TMPDIR/pvdman-error.log 1> $TMPDIR/pvd-man.log &
    else
      python3 $PVDMAN/main.py 2>$TMPDIR/pvdman-error.log 1> $TMPDIR/pvd-man.log &
    fi
    echo "mif-pvd man started"
    echo "start pvd-aware programs now"

  else

    # R1/R2/S1/S2
    sysctl -w net.ipv6.conf.all.forwarding=1

    if [ -z "$DEV1" -o -z "$IP1NET" ]; then
      echo "DEV1 and IP1NET must be provided for $ROLE"
      stop && exit 1
    fi
    /sbin/ip -6 addr add $IP1NET dev $DEV1

    # http
    systemctl stop $HTTPDPROG.service
    source $DEMOHOME/httpd.conf > $HTTPDCONFDIR/pvd-httpd.conf
    mkdir -p $HTTPDPVD
    source $DEMOHOME/pvd-info.json > $HTTPDPVD/pvd-info.json
    source $DEMOHOME/index.html > $HTTPDHTML/index.html
    systemctl start $HTTPDPROG.service

    if [ "$ROLE" = "R1" -o "$ROLE" = "R2" ]; then
      if [ -z "$IP2NET" ]; then
        echo "Address for DEV2 must be provided for $ROLE"
        stop && exit 1
      fi
      /sbin/ip -6 addr add $IP2NET dev $DEV2
      source $DEMOHOME/radvd.conf > $TMPDIR/radvd.conf
      $RADVD -d 5 -n -C $TMPDIR/radvd.conf -m logfile -l $TMPDIR/radvd.log &
      echo "radvd started"
    else
      # start echo udp server
      if [ ! -f $TESTAPPS/echo_server ]; then
        ( cd $TESTAPPS/ && make echo_server )
      fi
      sleep 1 # wait for IP address to be really assigned before binding to it
      $TESTAPPS/echo_server "$IP1" 20000 > $TMPDIR/echo_server.log &
    fi

    # if some routes need to be added on server or routers
    if [ -n "$ROUTE1_ADD" ]; then eval $ROUTE1_ADD; fi
    if [ -n "$ROUTE2_ADD" ]; then eval $ROUTE2_ADD; fi
    if [ -n "$ROUTE3_ADD" ]; then eval $ROUTE3_ADD; fi
  fi
  return 0
}

function stop {
  # enable other connections
  if [ -n "$DEV0" ]; then
    nmcli device connect $DEV0
  fi

  if [ "$ROLE" = "C" ]; then
    killall -SIGINT python3 && echo "mif-pvd man stopped"
    py3clean $PVDMAN

  else

    # R1/R2/S1/S2
    sysctl -w net.ipv6.conf.all.forwarding=0

    if [ -n "$IP1NET" ]; then
      /sbin/ip -6 addr del $IP1NET dev $DEV1
    fi
    if [ "$ROLE" = "R1" -o "$ROLE" = "R2" ]; then
      if [ -n "$IP2NET" ]; then
        /sbin/ip -6 addr del $IP2NET dev $DEV2
      fi
      killall radvd && echo "radvd stopped"
    else
      killall echo_server && echo "echo_server stopped"
    fi

    # http
    systemctl stop $HTTPDPROG.service
    rm -f $HTTPDCONFDIR/pvd-httpd.conf
    rm -rf $HTTPDPVD
    rm -f $HTTPDHTML/index.html

    if [ -n "$ROUTE1_DEL" ]; then eval $ROUTE1_DEL; fi
    if [ -n "$ROUTE2_DEL" ]; then eval $ROUTE2_DEL; fi
    if [ -n "$ROUTE3_DEL" ]; then eval $ROUTE3_DEL; fi
  fi
  return 0
}

function clean {
  stop
  rm -rf $TMPDIR
  rm -f /etc/dbus-1/system.d/dbus-pvd-man.conf
  ( cd $TESTAPPS && make clean )
}

# get settings
source ./${ROLE}_conf.sh

# call function for given command
eval $COMMAND
