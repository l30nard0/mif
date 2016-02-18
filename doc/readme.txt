PvD architecture overview / implementation details (work in progress)
=====================================================================
This document describes a proof-of-concept implementation of provisioning domain
(PvD) aware client-side network management component (MIF-pvdman). The source
code is available at https://github.com/dskvorc/mif-pvdman.

Contents
--------
1. Architecture Overview and Implementation Details
2. PvD Properties
3. Overview of Development Environment
4. Summary of design decisions used in implementation
5. TODO list

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

Upon receiving PvD information from router, MIF-pvdman tries to get a file with
PvD properties from the same router. If such file exists, network related PvD
parameters are extended with ones (properties) from received file.

Client application receives all those additional properties on request, and may
select appropriate PvD based on them.

Current implementation is very rudimentary: files on router are in JSON format.
MIF-pvdman interpret them - create a dcitionary of them, but only because
MIF-pvdman its written in Python and using JSON is easy, while client
applications are written in C. In real implementation this should be reversed -
only client should interpret file with PvDs' properties.

Properties used in this prototype are just an example (name, type, bandwith,
price), not to be used in some protocol specification.
The idea is to present mechanism to provide additional PvD properties obtained
by some mechanism (not by RAs) and let client application decide what to do with
them.

Examples for PvD properties:
[
    {
		"name": "Home internet access",
		"type": ["internet", "wired"],
		"id": "implicit",
		"bandwidth": "10 Mbps",
		"pricing": "free"
	},
	{
		"name": "voip",
		"type": ["iptv", "wired"],
		"id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3e",
		"bandwidth": "10 Mbps",
		"pricing": "free"
	},
	{
		"name": "Cellular internet access",
		"type": ["internet", "cellular"],
		"id": "implicit",
		"bandwidth": "1 Mbps",
		"pricing": "0,01 $/MB"
	},
	{
		"name": "Internet access over Lucy's phone",
		"type": ["general", "cellular"],
		"id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3f",
		"bandwidth": "0,1 Mbps",
		"pricing": "0,01 $/MB"
	}
]


3. Overview of Development Environment
--------------------------------------
Prototype system implementation described above is implemented and tested on
Linux/Fedora 23 and Linux/Lbuntu 15.10. Test environment consists of minimum two
machines, one being a router running radvd, while another being a regular host
running MIF-pvdman and client applications. Additional routers and "servers"
behind routers are used in some demonstrations.
In our experiments, we used virtual machines hosted in VMware Player.

Services on routers (Rx) and servers (Sx):
- radvd (PvD-aware NDP server) (only on routers):
  * https://github.com/dskvorc/mif-radvd
- web server (httpd, apache2)
- DNS server (bind)
- test applications (echo_server, ...)

Service on client - MIF-pvdman:
- directory "pvdman"
- requires python3 + netaddr + pyroute2 modules
- MIF-pvdman modules:
  * main.py
    - start services, connects modules, respond on events
    - start with: sudo python2 main.py [-i <interface-name>]
  * pvdman.py
    - keeps and manages PvD data
    - creates/updates PvDs on demand
  * ndpclient.py
    - listen for RAs (sends RS on startup)
    - from received RAs create PvDs calling pvdman.py's setPvd
  * pvdserver.py
    - responds to d-bus requests from client applications and sends them PvD
      information back

Legacy, PvD unaware application:
- for it to use PvDs it should be started with:
  * ip netns exec:
    $ ip netns exec <namespace-name> <application-name> [arguments...]
  * or MIF launchers pvd_run or pvd_prop_run:
    $ sudo ./pvd_run <pvd-id> <application-name> [arguments...]
    $ sudo ./pvd_prop_run <req-properties> <application-name> [arguments...]

MIF aware applications on client:
- use C API, directory "api"
- sample application in directory "testapps"
- client side API:
  * written for C programming language
  * requires glib2-devel package
  * uses d-bus to connect to MIF-pvdman (module pvdserver.py)
  * methods:
    - pvd_get_by_id - get a list of PvDs which id contains given string
    - pvd_get_by_properties - get a list of PvDs which have requested properties
    - pvd_activate:
      * get PvD with given id
      * save information about which PvDs are used (this isn't implemented yet;
        is it required/useful?)
      * switch calling thread (process) into given PvD (namespace)
    - pvd_reset - switch application back to default namespace (not managed by
      MIF-pvdman)
- using API:
  * pvd_activate (and possibly pvd_get_by_id/pvd_get_by_properties before it)
    - before socket is opened, and before other network related operations like
      getaddrinfo, gethostbyname and similar that preceed "socket" a PvD must be
      selected with pvd_activate
    - additional socket control operations like bind/setsockopt can be used then
  * if required, another socket can be opened in same/another PvD
  * as long as PvDs socket was created in is operational, other send/receive
    operations on that socket should work as expected
- test applications:
  * some test applications are implemented in "testapps"
  * pvd_list, pvd_run, pvd_prop_run, ...
  * usage: sudo ./<prog> [arguments]

Test Case:
- test cases and results are presented in directory "demos"


4. Summary of design decisions used in implementation

- Linux namespaces as PvD isolation mechanism
  * Single PvD resides within single PvD. This choice is discussed in design
    document (Modifications on Fedora to support MIF).
- Router Advertisement as PvD information delivery
  * Since draft which proposes DHCP as second PvD information provider is
    withdrawn (IPR claims) only RAs are left.
  * Service radvd is modified to carry PvD information, as per draft
    draft-ietf-mif-mpvd-ndp-support-02
  * Explicit PvD information is carried inside PvD container options.
  * Each RA will contain all PvDs defined in radvd.conf.
  * For PvD identity option UUID [RFC4122] is used.
  * Single PvD container must contain options related to single PvD, and must
    carry single PvD identity option.
  * Parameters outside PvD container form "implicit" PvD with PvD identity that
    is generated from constant parameters (not timeouts) so that same
    parameters always produce same PvD ID.
- Python 3 with pyroute2 module for MIF-pvdman
  * Python 3 is chosen for rapid prototyping
  * module pyroute2 is used for most network related operations
- IPv6 address family
  * since RAs are used, implementation is started for IPv6
  * adding support for IPv4 would require (best guess):
    - PvD information with IPv4 network parameters (DHCP, file from router, ...)
    - changes in MIF-pvdman
    - dual stack PvDs
- D-bus for communication with client MIF-aware applications
  * why:
    - d-bus is "popular" choice for communication with system services
    - NetworkManager uses d-bus (if this implementation is to be merged with it)
  * MIF-pvdman offer services
  * MIF-aware application call services (using prived API from "api")
- API
  * pvd_get_by_id
  * pvd_get_by_properties
  * pvd_activate


5. TODO list

- PvD information delivery
  * RA/RS options:
    - each RA delivers all PvD information (current implementation)
    - RA just indicate that he has PvD information - delivery on request
    - ...
  * DHCP
  * ?
- MIF-pvdman
  * IPv4
  * ...
- API
  * permission to switch namespace to user application
    - probably requires a little kernel modification
  * signal client about change in PvDs on the system
    - implementation in progress
  * change which resolv.conf is used (should be: /etc/netns/<ns-name/resolv.conf)
    - change glibc? library
    - track what "ip netns exec" do (mount something) and do it in api
