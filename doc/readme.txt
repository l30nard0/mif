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
4. Using MIF prototype
5. Summary of design decisions used in implementation
6. Implementation problems, workarounds and TODOs

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

 +-------------------------------------------------------+    +--------------+
 | +---------------------------------------------------+ |    |    +-------+ |
 | | MIF-pvdman                                        | |    | +--+ radvd | |
 | | +-----------+     +-----------+     +-----------+ | |    | |  +-------+ |
 | | | pvdserver +-->--+   pvdman  +--<--+ ndpclient | | |    | |            |
 | | +-----+-----+     +-------+---+     +-----+-----+ | |    | |  +-------+ |
 | +-------|-------------------|---------------|-------+ |    | +--+ httpd | |
 |         |d-bus        create|configure      |RA/RS    |    | |  +-------+ |
 | get_pvds|             delete|               |HTTP     |    | |            |
 | +-------|-------+    +------+-------+       |         |    | |            |
 | | +-----+-----+ |join|   network    |     --+---------+----+-+--        --+--
 | | |  MIF API  +------+  namespace   |                 |    |              |
 | | +-----------+ |    |  operations  |                 |    |              |
 | |               |    +--------------+                 |    |              |
 | |   MIF aware   |                                     |    |              |
 | |  application  |                                     |    |              |
 | +---------------+                        Client (PC)  |    |      Router  |
 +-------------------------------------------------------+    +--------------+

                Figure 1. MIF prototype architecture overview

MIF-pvdman receives network configurations through Router Advertisement messages
(RAs). Modified version of PvD-aware radvd is used. Each RA may contain one or
more network configurations which are classified either as explicit or implicit
PvDs. Explicit PvD is a set of coherent NDP options explicitly labeled with a
unique PvD identifier and nested within a special NDP option called PVD
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
on which the related PvD information is received through the RA. Each virtual
interface is assigned a link-local IPv6 address (fe80::/64) and one or more
addresses derived from Prefix Information options if present in the received RA.
Besides the IP addresses, MIF-pvdman configures the routing tables and DNS
records within the namespace. By default, a link-local and default route via the
RA-announcing router are added to the routing table, regardless of the routing
information received in RA. Additional routing information is configured if
Route Information options are received in RA.
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
that namespace. Once obtained by the application, socket handles are linked to
the network namespace they were originally obtained from and continue to work in
that namespace, regardles of whether the application switches to another
namespace at some time later. This enables the application to use multiple PvDs
simultaneously. The only requirement is that the application is running within a
proper network namespace while obtaining a socket.

Non-PvD aware clients operate as before. Although they are not able to use PvD
API to select a certain PvD, they can still be forced to use a specific PvD by
starting them in a network namespace associated with that PvD. To run a program
within a given namespace, it should be started with:

    ip netns exec <pvd-namespace-name> <command with args>

or they can be started with launchers pvd_run and pvd_prop_run (detailed later).


2. PvD Properties
-----------------
With RA messages routers provides network relate parameters for PvDs.
Other parameters (in this "draft" called "properties") are also provided by
router, but only on request, using HTTP protocol on router's link-local address,
using port 8080.

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


4. Using MIF prototype
----------------------

4.1. Legacy, PvD unaware applications

To use PvDs an PvD unaware applications should be started:

  * with: ip netns exec
    $ ip netns exec <namespace-name> <application-name> [arguments...]
      e.g.: ip netns exec mifpvd-1 firefox http://www.pvd1.org

  * or with MIF launchers: pvd_run or pvd_prop_run:
    $ sudo ./pvd_run <pvd-id> <application-name> [arguments...]
      e.g.: pvd_run bbffa8f5-0db3-5e6b-b585-c2ebd1a92af5 wget http://www.pvd1.org

    $ sudo ./pvd_prop_run <req-properties> <application-name> [arguments...]
      e.g.: pvd_prop_run "{\"type\": \"internet\", \"pricing\": \"free\"}" \
            wget http://www.pvd1.org

4.2. MIF aware applications

MIF aware applications are created using C API, from directory "api".
Sample application are presented in directory "testapps".

Properties of API:
- API is written for C programming language
- requires glib2-devel package
- uses d-bus to connect to MIF-pvdman (with its module pvdserver.py)
- methods provided by API:
  * pvd_get_by_id - get a list of PvDs which id matches (contains) given string
  * pvd_get_by_properties - get a list of PvDs which have requested properties
  * pvd_activate:
    - retrieve PvD with given id
    - TODO: MIF-pvdman should save information about which PvDs are used
    - switch calling thread (process) into given PvD (namespace)
  * pvd_reset - switch application back to default namespace (not managed by
    MIF-pvdman)

API usage reccomentations/steps
1. Use calls to pvd_get_by_id/pvd_get_by_properties to get desired PvD Id.
2. Call pvd_activate to switch thread/process to desired PvD.
3. Call operations that precede "socket", like getaddrinfo, gethostbyname, ...
4. Open socket
5. Call (control) operations on created socket, like bind, setsockopt, ...
6. Socket is ready to be used.
Switching to another PvD will not affect already opened and prepared socket.
Opening socket in another PvD (besides already opened ones) should follow the
same procedure: steps 1 to 6.
As long as PvD socket was created in is operational, other network related
operations like send and receive on that socket should work as expected, in
selected PvD.

Test applications prepared in "testapps" should be compiled with make [appname]
and started with: sudo ./appname [arguments]

Demonstration test cases are presented in directory "demos", along with sample
output from test runs.


5. Summary of design decisions used in implementation
-----------------------------------------------------
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
- HTTP protocol and HTTP server on routers for delivering PvD properties
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
  * MIF-aware application call services (using API from "api")
- API
  * pvd_get_by_id
  * pvd_get_by_properties
  * pvd_activate
  * pvd_reset


6. Implementation problems, workarounds, discussion and TODOs
-------------------------------------------------------------

6.1. PvD information delivery

6.1.1. PvD network related informations

6.1.1.1. Router Advertisement messages

In designed prototype only Router Advertisement messages (RA) are used.
Modified radvd delivers all PVD information it has with each RA.
Other possibilities are discussed in separate document.


6.1.1.2. DHCP

DHCP can be used to deliver PvD informations, but it isn't implemented since
IPR claim was set for particular draft. Given IPR claim is too wide, any
implementation that carry PvD information will violate it.
If any DHCP implementation should be possible that claim must be removed.


6.1.2. PvD properties

Since question "What are PvD properties?" is unresolved, only demo properties
are shown in this prototype, we focused on delivery mechanism.
To us, most obvious choice was to use some other mechanism, not one used to
deliver PvD network informations. Same mechanisms are used by web browsers to
detect proxy servers and similar settings.
Embedding such properties within RAs (or in future DHCP) messages might be
problematic since those messages might grow to big.

In MIF prototype routers that delivered network parameters for PvDs are also
chosen to deliver PvD properties. They are first choice since client have their
link-local address and can contact them even before client brings its network
interface fully up (e.g. before assignment of its public IP address).
Alternative, which we considered, was to add an option to RA message which can
carry a link to URL which will provide PvD properties. However, this approach
might require that related PvD is first brought up, and from within remote
server contacted and PvD properties received. Similar mechanism could still be
achieved with router which can redirect its HTTP request to remote location
(and adding option to RA isn't required).

PvD properties format used is prototype is JSON (implementation reasons).
Similar formats, as XML, will achieve same thing.


6.2. Using Linux network namespaces

Decission "why namespaces are used" is present in section 1 and design document
Modifications on Fedora to support MIF. Some may argue that this is to specific
choice working only on Linux. However, since Android is based on Linux, systems
that could potentially implement presented MIF managment are very numerous.

Linux network namespace mechanism is used to separate network stack from link
layer (L2) up. Its introduced as a container mechanism which allows process and
network isolation for special applications (e.g. instead of using "whole Linux
operating system" in sparate virtual machine, a container is created using
namespaces and an application is run within).

Required separation for PvD implementation require separation at Internet layer
(L3), which will provide different routing and DNS (possibly different DNS
servers) per PvD. Since no simple solution was found on L3, namespaces are used.
Namespaces are simple ("elegant") solution, but maybe too strong and demanding
for operating system (or maybe not).
Furthermore, namespaces isolate network parameters from link layer, and they
impose some restrictions and additions to MIF PvD model.

To create a PvD that will use (physical) interface, two options are available:
1. Clone interface into new one which will have its own L2 and L3 addresses and
   other network parameters (e.g. using macvlan driver), and move only this
   cloned interface into a new namespace created for this particular PvD.
2. Move original interface into a new namespace created for this particular PvD.
First approach (clone) is used when PvDs are based on ethernet based interface,
while second is used for special connections like VPN (as shown in demo-30).
The second approach changes "root" namespace since interface is moved out of it.
However, such connection is "special", and separating it from the rest is for
benefit of the system since it might have conflicting parameters with other
interfaces (e.g. when VPN is used to connect with a remote network that has the
same prefix as client's local network).
If interface isn't such special one, moving it out of "root" namespace might not
be the best idea - other solutions should be used (maybe using bridges).

Problems encountered with Linux namespaces are:
a) L2 (and up) emulation, while L3 would be better.
   As consequence, each PvD must have its own IP address. While this isn't big
   problem with IPv6 addresses its not so with IPv4. We might argue that even
   with IPv4, when local addresses are used (10.0.0.0/8, 172.16.0.0/12 and
   192.168.0.0/16) there might be enough local addresses (with planning).
   However, when public IPv4 addresses are used this solution isn't appropriate!
   On the other hand, IPv6 should be future of Internet and maybe PvD could be
   implemented with IPv6 in mind? And again, maybe some kind on lightweight
   namespaces will appear in future operating systems, which isolate L3 and up.

b) Switching between namespaces requires root privileges.
   In current implementation of Linux namespaces, only root can create a new
   namespace and move a process to it. This is a problem since MIF aware
   applications are user's applications, without root privileges.
   For now, we run applications as root.

   If this issue must be resolved for MIF PvD support, it would include changes
   in namespace privileges, adding privileges on namespaces: which user/group
   can switch to certain namespaces. E.g. same as privileges that are set on
   files and almost all other system resources.

c) Using specific resolv.conf - specific DNS in different namespace.
   For each namespace separate resolv.conf can be set via configuration in
   /etc/netns/<namespace-name>/resolv.conf.
   When starting some program in specific namespace using "ip netns exec"
   utility, this utility performs some "mount operation" before starting program
   in that namespace. Result of this mounting is that file
   /var/run/resolvconf/resolv.conf is a copy of
   /etc/netns/<namespace-name>/resolv.conf.
   File /etc/resolv.conf which is used by namespace-unaware applications is a
   link to /var/run/resolvconf/resolv.conf

   However, when switching to some namespace from program using "setns" function
   no such mounting is performed. And while /etc/resolv.conf is still link to
   /var/run/resolvconf/resolv.conf, this file isn't one from
   etc/netns/<namespace-name>.
   Operation of "ip netns exec" should be investigated further to replicate such
   process. Alternative is to adapt some library (glibc?) which implement DNS
   related operations so that they first check for presence of
   /etc/netns/<namespace-name>/resolv.conf and use it if present, before
   checking configuration in /etc/resolv.conf


6.3. PvD related events handling

What to do when some MIF PvD related change occur while some MIF aware
application is already running?
There are several possibilities:
a) do nothing
b) signal to the application that change occurred if application is registered
   for such events
c) same as b) but with addition to what the change is about

Issue that should be also considered here is WHEN the MIF manager detect changes.

i)  New PvDs are announced by RA which are issued periodically or when something
    goes in UP state.

ii) When PvD goes down its usually because link went down (e.g. no more in Wi-Fi
    range). Of course such event can be also announced via RAs (e.g. by setting
    some timeout to zero in network related parameters - prefix), but it should
    be expected that this will occur rarely.
    Therefore, its more realistic that an application will detect PvD is down
    before MIF manager. Maybe we should design an API which an application will
    use to contact MIF manager and to signal it about a problem with specific
    PvD. MIF manager can then recheck such PvD and its connections (and remove
    it if down).
    Or MIF manager can periodically test all PvDs (indirectly).

    In current implementation network parameters have timeouts. Each new RA
    refresh those timeouts. When timeouts expire related PvDs can be removed
    (this feature is planned but not implemented yet).
    Another indirect mechanism (included in prototype) is to check for router
    state with simple ICMP message (ping). When router doesn't respond, all
    PvDs that originate from that router are removed.

Since "PvD down" event will be detected by application, more focus should be set
on signaling "PvD up" event, when some possibly more favorable PvD is created.
TODO


6.4. MIF API
------------
MIF API consists of several methods. Most methods first contact MIF-pvdman to
obtain a list of PvDs and then performe some operations on them: select one PvD
and switch to that PvD. Other methods (like pvd_reset) doesn't use MIF-pvdman.
In this scenario, MIF-pvdman just serves information about PvDs to application,
and single interface "mif_get_pvds" could be sufficient.

TODO signals

