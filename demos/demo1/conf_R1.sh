#!/bin/bash

NAME="R1"

IND=1

# Update values here!

# assuming: DEV0 - general internet access - not to be used during test
#           DEV1, DEV2 - for tests, have assigned link-local IPv6 addresses
DEV0=eno16777736 # device that should be turned off during tests
DEV1=eno33554984 # first device used in tests
DEV2=eno50332208 # second device usen in tests (empty if not used)

# IP addresses
IP1="2001:db8:${IND}::1"   # for DEV1
IP2="2001:db8:${IND}0::1"  # for DEV2
IP1NET="$IP1/48"
IP2NET="$IP2/32"

# DNS
STARTNAMED="yes"

# radvd configuration
STARTRADVD="yes"
PVD_1_ID="implicit"
PVD_2_ID="f037ea62-ee4f-44e4-825c-16f2f5cc9b3f"

# pvd properties
PVD_1_TYPE="[\"internet\", \"wired\"]"
PVD_1_NAME="Home internet access"
PVD_1_BANDWITH="10 Mbps"
PVD_1_PRICING="free"
PVD_2_TYPE="[\"iptv\", \"wired\"]"
PVD_2_NAME="TV"
PVD_2_BANDWITH="10 Mbps"
PVD_2_PRICING="free"

# HTTPD
STARTHTTPD="yes"

# echo server
CUSTOMSERVERAPP="echo_server"
