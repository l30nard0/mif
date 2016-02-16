#!/bin/bash

function Usage () {
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
TMPDIR=$DEMOHOME/__mif_cache__
TESTAPPS=$REPOROOT/testapps
TMPLDIR=$DEMOHOME/templates

# get settings from node's configuration file
source $DEMOHOME/conf_${ROLE}.sh

# dns server
NAMEDCONFDIR=/etc/bind
NAMEDCONF=named.conf # or named.conf.local for lubuntu
DNSPVDZONE=pvd${IND}.org
NAMEDPVDZONEFILE=${DNSPVDZONE}.db

# radvd
PVD_1_PREFIX="2001:db8:${IND}:1::/64"
PVD_1_ROUTE="2001:db8:${IND}:1::/64"
PVD_1_DNSSL="$DNSPVDZONE"
PVD_1_RDNSS="2001:db8:${IND}::1 2001:db8:${IND}0::2"
PVD_2_PREFIX="2001:db8:${IND}:2::/64"
PVD_2_ROUTE="2001:db8:${IND}:2::/64"
PVD_2_DNSSL="$DNSPVDZONE"
PVD_2_RDNSS="2001:db8:${IND}::1 2001:db8:${IND}0::2"

# web server
HTTPDCONFDIR=/etc/apache2/sites-enabled
HTTPDHTML=/var/www/html
HTTPDPVD=/var/www/html/_pvd_info_

function start {
  mkdir -p $TMPDIR

  # disable other connections (NetworkManager)
  if [ -n "$DEV0" ]; then
    nmcli device disconnect $DEV0
  fi

  if [ "$ROLE" = "C" ]; then
    client_start
  else
    # R1/R2/S1/S2 - very similar

    # ip addresses
    sysctl -w net.ipv6.conf.all.forwarding=1
    if [ -z "$DEV1" -o -z "$IP1NET" ]; then
      echo "DEV1 and IP1NET must be provided for $ROLE"
      stop && exit 1
    fi
    /sbin/ip -6 addr add $IP1NET dev $DEV1
    if [ "$ROLE" = "R1" -o "$ROLE" = "R2" ]; then
      if [ -z "$IP2NET" ]; then
        echo "Address for DEV2 must be provided for $ROLE"
        stop && exit 1
      fi
      /sbin/ip -6 addr add $IP2NET dev $DEV2
    fi

    # dns server
    if [ -n "$STARTNAMED" ]; then
      if [ ! -f $NAMEDCONFDIR/$NAMEDCONF.orig ]; then
        cp $NAMEDCONFDIR/$NAMEDCONF $NAMEDCONFDIR/$NAMEDCONF.orig
      fi
      # test if zone is already defined in $NAMEDCONF
      grep $DNSPVDZONE < $NAMEDCONFDIR/$NAMEDCONF > /dev/null
      if [ $? != 0 ]; then
        source $TMPLDIR/bind_append.conf >> $NAMEDCONFDIR/$NAMEDCONF
      fi
      source $TMPLDIR/pvd-zone.db > $NAMEDCONFDIR/$NAMEDPVDZONEFILE
      systemctl restart bind9.service
      echo "dns server started"
    fi

    # web server
    if [ -n "$STARTHTTPD" ]; then
      source $TMPLDIR/httpd.conf > $HTTPDCONFDIR/pvd-httpd.conf
      mkdir -p $HTTPDPVD
      source $TMPLDIR/pvd-info.json > $HTTPDPVD/pvd-info.json
      source $TMPLDIR/index.html.tmpl > $HTTPDHTML/index.html
      systemctl restart apache2.service
      echo "web server started"
    fi

    # radvd server
    if [ -n "$STARTRADVD" ]; then
      source $TMPLDIR/radvd.conf > $TMPDIR/radvd.conf
      /usr/local/sbin/radvd -d 5 -n -C $TMPDIR/radvd.conf -m logfile -l $TMPDIR/radvd.log &
      echo "radvd started"
    fi

    # custom server (for testing purposes)
    if [ -n "$CUSTOMSERVERAPP" ]; then
      if [ ! -f $TESTAPPS/$CUSTOMSERVERAPP ]; then
        ( cd $TESTAPPS/ && make $CUSTOMSERVERAPP )
      fi
      sleep 1 # wait for IP address to be really assigned before binding to it
      $TESTAPPS/$CUSTOMSERVERAPP $IP1 20000 > $TMPDIR/$CUSTOMSERVERAPP.log &
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
    client_stop
  else

    # R1/R2/S1/S2
    sysctl -w net.ipv6.conf.all.forwarding=0

    if [ -n "$STARTNAMED" ]; then systemctl stop bind9.service; fi
    if [ -n "$STARTHTTPD" ]; then systemctl stop apache2.service; fi
    if [ -n "$STARTRADVD" ]; then killall radvd; fi
    if [ -n "$CUSTOMSERVERAPP" ]; then killall $CUSTOMSERVERAPP; fi

    if [ -n "$IP1NET" ]; then /sbin/ip -6 addr del $IP1NET dev $DEV1; fi
    if [ -n "$IP2NET" ]; then /sbin/ip -6 addr del $IP2NET dev $DEV2; fi

    if [ -n "$ROUTE1_DEL" ]; then eval $ROUTE1_DEL; fi
    if [ -n "$ROUTE2_DEL" ]; then eval $ROUTE2_DEL; fi
    if [ -n "$ROUTE3_DEL" ]; then eval $ROUTE3_DEL; fi

  fi
  return 0
}

function clean { # logs, applications, ...
  stop
  if [ "$ROLE" = "C" ]; then
    client_clean
  else
    rm -f $HTTPDCONFDIR/pvd-httpd.conf
    rm -rf $HTTPDPVD
    rm -f $HTTPDHTML/index.html
    rm -f $NAMEDCONFDIR/$NAMEDPVDZONEFILE
    if [ -f $NAMEDCONFDIR/$NAMEDCONF.orig ]; then
      cp $NAMEDCONFDIR/$NAMEDCONF.orig $NAMEDCONFDIR/$NAMEDCONF
    fi
  fi
  rm -rf $TMPDIR
  ( cd $TESTAPPS && make clean )
}

# call function for given command
eval $COMMAND

