#!/usr/bin/env python3

import sys, argparse, pyroute2, socket


parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers ( dest='command' )

parser_create = subparsers.add_parser('create', help='Add IP address and create a tunnel')
parser_create.add_argument ( '--tunnel', '-t', required=True, type=str, help='Tunnel name', dest='tunnel' )
parser_create.add_argument ( '--local', '-l', required=True, type=str, help='Local address for tunnel', dest='local' )
parser_create.add_argument ( '--remote', '-r', required=True, type=str, help='Remote address for tunnel', dest='remote' )
parser_create.add_argument ( '--iface', '-i', required=True, type=str, help='Interface where to add tunnel', dest='iface' )

parser_delete = subparsers.add_parser('delete', help='Delete IP address and a tunnel')
parser_delete.add_argument ( '--tunnel', '-t', required=True, type=str, help='Tunnel name', dest='tunnel' )
parser_delete.add_argument ( '--local', '-l', required=True, type=str, help='Local address to delete', dest='local' )
parser_delete.add_argument ( '--iface', '-i', required=True, type=str, help='Interface where to add tunnel', dest='iface' )

arg = parser.parse_args()

print ( str(arg) )
sys.exit(1)

local = arg.local
remote = arg.remote
iface = arg.iface

IFACE="eno33554984"
LOCAL_IP="2001:db8:2::2"
REMOTE_IP="2001:db8:20::2"

# add IP address to interface
ipr = pyroute2.IPRoute()
ifaceIndex = ipr.link_lookup ( ifname = iface )[0]
ipr.addr ( 'add', index=ifaceIndex, address=local, prefixlen=64, rtproto='RTPROT_RA', family=socket.AF_INET6 )

# create a tunnel
