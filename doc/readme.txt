PvD architecture overview / implementation details
===================================================
This document describes a proof-of-concept implementation of provisioning domain
(PvD) aware client-side network management component (MIF-pvdman). The source
code is available at https://github.com/dskvorc/mif-pvdman.

Contents
--------
1. Architecture Overview and Implementation Details
2. PvD Properties
3. Overview of Test Environment

1. Architecture Overview and Implementation Details
---------------------------------------------------
MIF-pvdman is a client-side component for IPv6 network auto-configuration based
on multiple provisioning domains (PvDs), as described in RFC 6418 and RFC 7556
(https://tools.ietf.org/html/rfc6418, https://tools.ietf.org/html/rfc7556).
MIF-pvdman is orthogonal to existing system, which means it does not interfere
with regular network behavior: none of the services and settings used by Network
Manager and similar components are not changed nor affected.

PvDs are implemented through Linux network namespaces. For each coherent PvD
information set received on the network interface, MIF-pvdman creates a separate
network namespace and configures received network parameters within that
namespace. Since each network namespace uses separate IP stack which is isolated
from other namespaces, potentially conflicting network parameters received from
different network providers can safely coexist on a single host. MIF-pvdman
manages only those newly created namespaces associated with the PvDs and their
network settings and leaves the default network namespace intact. That way, all
the existing network management components, such as Network Manager, continue to
work unobtrusively.

MIF-pvdman receives network configurations through Router Advertisement messages
(RAs). Modified version of PvD-aware radvd is used (1). Each RA may contain one
or more network configurations which are classified either as explicit or
implicit PvDs. Explicit PvD is a set of coherent NDP options explicitly labeled
with a unique PvD identifier and nested within a special NDP option called PVD
container, as described in draft-ietf-mif-mpvd-ndp-support-02
(https://tools.ietf.org/html/draft-ietf-mif-mpvd-ndp-support-02). Multiple
explicit PvDs may appear in a single RA, each within a different PvD container
option, as long as they are labeled with different PvD identifiers. Implicit PvD
is just another name for top-level NDP options placed outside the PvD container
option, as in regular non-PvD-aware router advertisements. Since implicit PvDs
are not labeled with PvD identifier, MIF-pvdman automatically generates an
identifier for internal use and configures the implicit PvD on the host in the
same way as if it was the explicit one. Only one implicit PvD is allowed per RA.
In current prototype, UUID is used as a PvD identifier.

Each PvD, either explicit or implicit, is associated with a network namespace
with a single virtual network interface (besides the loopback) of macvlan type,
where PvD-related network parameters are configured. To establish a connectivity
to the outside world, virtual interface is connected to the physical interface
on which the related PvD information is received through the RA (2). Each
virtual interface is assigned a link-local IPv6 address (fe80::/64) and one or
more addresses derived from Prefix Information options if present in the
received RA (3). Besides the IP addresses, MIF-pvdman configures the routing
tables and DNS records within the namespace. By default, a link-local and
default route via the RA-announcing router are added to the routing table,
regardless of the routing information received in RA. Additional routing
information is configured if Route Information options are received in RA.
Finally, for each RDNSS and DNSSL option received in RA, MIF-pvdman creates a
record in /etc/netns/NETNS_NAME/resolv.conf, where NETNS_NAME is a name of the
network namespace associated with the PvD.

PvD-aware client application uses PvD API to get a list of available PvDs
configured on the local host, and activate chosen PvD to use it for
communication. Information about configured PvDs are exposed to applications by
a special PvD service running on local host. D-Bus is used to connect
applications to PvD service. Upon PvD activation, client application is switched
to the network namespace associated with the selected PvD. Further network
operations (socket creation, sending and receiving data) are performed within
that namespace (4). Once obtained by the application, socket handles are linked
to the network namespace they were originally obtained from and continue to work
in that namespace, regardles of whether the application switches to another
namespace at some time later. This enables the application to use multiple PvDs
simultaneously. The only requirement is that the application is running within a
proper network namespace while obtaining a socket.

Non-PvD aware clients operate as before. Although they are not able to use PvD
API to select a certain PvD, they can still be forced to use a specific PvD by
starting them in a network namespace associated with that PvD. To run a program
within a given namespace, it should be started with:

    ip netns exec <pvd-namespace-name> <command with args>

(1) Modified PvD-aware radvd service is used
    https://github.com/dskvorc/mif-radvd
(2) Possibility for future extensions: if multiple PvDs should be grouped
    together for some reason, more virtual interfaces could be created per
    network namespace.
(3) Possibility (maybe/to be tested): maybe same IP address could be used in
    different PvDs (namespaces/interfaces) if they have different gateway
    (assuming kernel can forward received IP packet based on that).
(4) Problem: changing network namespace requires root privileges. Until more
    appropriate solution is found, applications are run as root.

2. PvD Properties
-----------------
With RA messages routers provides network relate parameters for PvDs.
Other parameters (in this "draft" called "properties") are also provided by
router, but only on request, using HTTP protocol on router's link-local address.

Upon receiving PvD information from router, MIF-pvdman tries to get file with
PvD properties from the same router. If such file exist, network related PvD
parameters are extended with ones (properties) from received file.

Client application receives all those additional properties on request, and may
request only those PvDs that match on requested property.

Current implementation is very rudimentary: files on router are in JSON format;
MIF-pvdman interpret them (because its written in Python and using JSON is easy,
while client applications are written in C).
In real implementation this should be reversed (only client should interpret
file with PvDs' properties).

Properties used in this example are just an example (name, type, bandwith, price).
The idea is to present mechanism to provide additional PvD properties obtained
by some mechanism (not by RAs) and let client application decide what to do with
them. Defining elements of properties is some IETF WG job, or it should be left
undefined (using specific properties in different environments).

Examples for PvD properties:
[
    {
		"name": "Home internet access",
		"type": ["general", "wired"],
		"id": "implicit",
		"bandwidth": "1 Mbps",
		"pricing": "free"
	},
	{
		"name": "voip",
		"type": ["voip"],
		"id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3e",
		"bandwidth": "10 Mbps",
		"pricing": "0,01 $/MB"
	},
	{
		"name": "TV",
		"type": ["iptv", "wired"],
		"id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3f",
		"bandwidth": "10 Mbps",
		"pricing": "free"
	},
	{
		"name": "Internet access over Lucy's phone",
		"type": ["general", "cellular"],
		"id": "implicit",
		"bandwidth": "10 Mbps",
		"pricing": "0,01 $/MB"
	}
]


3. Overview of Test Environment
----------------------------------
Prototype system implementation described above is implemented and tested on
Linux/Fedora 23 and Linux/Ubuntu 14.04. Test environment consists of two
machines, one being a router running radvd, while another being a regular host
running MIF-pvdman and client applications. In our experiments, we used two
virtual machines hosted in VMware Player.

Services on routers (Rx) and servers (Sx):
- radvd (PvD-aware NDP server) (only on routers):
  * https://github.com/dskvorc/mif-radvd
- web server (httpd, apache2)
- DNS server (bind)

Service on client - MIF-PvD:
- https://github.com/dskvorc/mif-pvdman
- start with scripts in "demos" or with sudo python3 main.py
  * (requires python3 + netaddr + pyroute2 modules)
- NDP client (ndpclient.py):
  * send RS request (on startup)
  * listen for RAs
  * from RAs creates implicit and explicit pvd information,
    and send them to pvdman
- PvD Manager (pvdman.py):
  * keeps PvD data
  * creates PvDs: namespaces, interfaces
  * updates PvDs with new parameters
- dbus service (pvdserver.py):
  * responds to dbus requests from clients (applications on localhost)

Application API:
- https://github.com/dskvorc/mif-pvdman/api
- api - library with client side API
  * uses dbus to connect to PvD Manager
  * methods: pvd_get_by_id, pvd_get_by_properties, pvd_activate
  * (requires glib2-devel package (libglib2-devel on fedora))
- API is used to select "current" PvD: all next network related operations
  will use that PvD (unless they were initialized before, in different PvD)
  until different PvD is selected

Test applications:
- in "testapps"
- pvd_list, pvd_run, pvd_prop_run, ...
- usage: sudo ./<prog> [arguments]


Test Case
---------
Test cases and results are presented in "demos" with configuration
and scripts and little documentation (start with readme.txt).
