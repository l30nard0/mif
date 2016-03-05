Demo 1 - presentation and discussions

Contents
1. Network setup
2. What can be demonstrated
2.1. Isolation
2.1.1. Example from RFC7566: 4.3. A Home Network and a Network Operator with
       Multiple PvDs (page 12)
2.1.2. Example from RFC7566: 4.2. A Node with a VPN Connection (page 12)
2.2. Mobility
2.1.3. Example from RFC7566: 4.1. A Mobile Node (page 11)
2.3. Application preference
2.4. Multi PvD applications


1. Network setup

Overall PvD architecture overview is presented in doc/readme.txt.

Network in this demo consists of client node (Client, C in scripts), two
routers R1 and R2 and two servers S1 and S2. Routers and servers have
static address configuration (as shown on Figure 1, set up with demo scripts).
(All nodes in test environment were virtual machines running Lubuntu 15.10.)


                fd01::1/64+------+                                   +------+
          2001:db8:1::1/64|      |2001:db8:10::1/32 2001:db8:10::2/32|      |
             +----------o-+  R1  +-o-------------------------------o-+  S1  |
+--------+   |            |      |        :     [VMnet3]             |      |
|        |   |            +------+        :                          +------+
| Client +-o-+ [VMnet2]                   : (for some tests this is linked)
|        |   |            +------+        :                          +------+
+--------+   |            |      |        :     [VMnet4]             |      |
             +----------o-+  R2  +-o-------------------------------o-+  S2  |
          2001:db8:2::1/64|      |2001:db8:20::1/32 2001:db8:20::2/32|      |
                fd02::1/64+------+                                   +------+

                Figure 1. Network configuration used in demos

Routers R1 and R2 on client side network [VMnet2] use public IP addresses
(2001:*) but also use private IP addresses (ULAs, fd0x*).

PvDs are identified by their ID. However, since UUID is used as ID (must be
unique), in this text shorter names are used as identifiers. For example name
R1-PvD1 refers to first PvD provided by R1 (first is usually implicit).
Real ID of this PvD will be different. Namespace created for this PvD will be
named "mifpvd-x" where "x" might be 1, 2, 3, ...

PvDs are defined for radvd servers as follows (*PvD1 implicit, *PvD2 explicit):
R1-PvD1: 2001:db8:1::/64 {"type":["internet", "wired"],    "bandwidth":"10 Mbps", "pricing":"free" }
R1-PvD2: fd01::/64       {"type":["iptv", "wired"],        "bandwidth":"10 Mbps", "pricing":"free" }
R2-PvD1: 2001:db8:2::/64 {"type":["internet", "cellular"], "bandwidth":"1 Mbps",  "pricing":"0,01 $/MB" }
R2-PvD2: fd02::/64       {"type":["voice", "cellular"],    "bandwidth":"1 Mbps",  "pricing":"0,01 $/MB" }

Applications/services on hosts:
Client: MIF-pvdman + custom created applications (testapps)
R1, R2: radvd, DNS server (bind), web server (apache2) + custom apps
S1, S2: DNS server (bind), web server (apache2) + custom apps
Configuration for DNS and web are same for R1 and S1, and for in R2 and S2.
Routes for S1 and S2:
- 2001:db8:1::/48 via 2001:db8:10::1 (for S2 only when VMnet4 == VMnet3)
- 2001:db8:2::/48 via 2001:db8:20::1 (for S1 only when VMnet4 == VMnet3)

Configuration is set via scripts. E.g. for R1:
- R1_conf.sh (R1 settings; settings are saved in environment variables)
- templates: radvd.conf, httpd.conf, bind_append.conf, pvd-zone.db
- run.sh - creates configuration files from templates using settings from
  R1_conf.sh, assign IP addresses to interfaces and starts services afterwards
  (radvd, apache2 and bind9)
Scripts are executed with: sudo ./run.sh <command> [<host>]
where <command> is one of "start", "stop" and "clean",
while <host> is one of C, R1, R2, S1 and S2 (can be ommited and derived from
host name).
Command "stop" will stop all started services and applications.
Command "clean" will first invoke "stop" and then restore system to previous
state (remove created configuration files, produced custom logs, compiled
application, temporary files created by services and applications).

For example, services on R1 are started with: sudo ./run.sh start R1


2. What can be demonstrated

2.1. Isolation

Single PvD can be configured for specific network only. Application that use
this PvD will see only its network, all other will be hidden in that PvD.
For example, different services (servers) like "internet", "video-on-demand"
could be defined through different PvDs that limit accessibility to only defined
services.

2.1.1. Example from RFC7566: 4.3. A Home Network and a Network Operator with
                                  Multiple PvDs (page 12)

>>>>
                <------ Implicit 'Internet' PvD ------>
           +----+     +-----+        _   __              _  _
           |    |     |     |       ( `    )            ( `   )_
           | PC +-----+     |-------------------------(         `)
           |    |     |     |     (         )        (_ Internet  _)
           +----+     |     |    (           )         `- __  _) -
                      |Home |   (   Service    )
                      |Gate-|   (  Provider's   )
                      |way  |   (   Network     -
           +-----+    |     |   `_            )        +-----------+
           | Set-|    |     |     (          )         |ISP Video- |
           | Top +----+     |--------------------------+on-Demand  |
           | Box |    |     |      (_     __)          | Service   |
           +-----+    +-----+        `- --             +-----------+
                 <-- Explicit 'Video-on-Demand' PvD -->

    Figure RFC7566-3: An Example of a Home Network and a Network Operator with
                      Multiple PvDs
<<<<
Using network from Figure 1, Client can simulate both PC and Set-Top Box with
two applications: one will use PvD1 to reach Internet, while second will use
PvD2 for reaching specific Video-on-Demand Service (Figure 2).

                         +-------------------+
                         | +-----------------+-------------+
                         | | PvD1 +------+   |    +------+ |
                  (PC) +-+-+----o-+  R1  +-o-+--o-+  S1  | | (Internet)
                       | | |      +------+   |    +------+ |
          +--------+   | | +-----------------+-------------+
          | Client +-o-+ |                   |
          +--------+   | | +-----------------+-------------+
                       | | | PvD2 +------+   |    +------+ | (ISP Video-
         (Set-Top Box) +-+-+----o-+  R2  +-o-+--o-+  S2  | |  on-Demand
                         | |      +------+   |    +------+ |  Service)
                         | +-----------------+-------------+
                         |   (Home Gateway)  |
                         +-------------------+

   Figure 2. Simulating Home Network and a Network Operator with Multiple PvDs

Script for demonstration:
- demo-01-01-C-run-testapps.sh (parts of)
- demo-02-01-C-req-free-internet.sh
- demo-02-02-C-req-voice.sh


2.1.2. Example from RFC7566: 4.2. A Node with a VPN Connection (page 12)

>>>>
             <----------- 'Internet' PvD ------>
    +--------+
    | +----+ |    +----+         _   __        _  _
    | |Phy | |    |    |        ( `    )      ( `   )_
    | |-IF +-|----+    |--------------------(         `)
    | |    | |    |    |      (         )  (_ Internet  _)
    | +----+ |    |    |     (           )   `- __  _) -
    |        |    |Home|    (   Service    )      ||
    |        |    |Gate|    (  Provider's   )     ||
    |        |    |-way|    (   Network     -     ||
    | +----+ |    |    |    `_            )  +---------+  +------------+
    | |VPN | |    |    |      (          )   |   VPN   |  |            |
    | |-IF +-|----+    |---------------------+ Gateway |--+  Private   |
    | |    | |    |    |       (_     __)    |         |  |  Services  |
    | +----+ |    +----+         `- --       +---------+  +------------+
    +--------+
             <-------------- Explicit 'VPN' PvD ----->

           Figure RFC7566-2: An Example of PvD Use with VPN
<<<<

VPN connection is simulated with IP tunnel between Client and S2 (over R2).
Public IPv6 addresses are used for tunnel endpoints.
Local network on client side uses fd02::/64.
Local network on S2 is the same fd02::/64 (different local network!).

            fd01::1/64+------+                                   +------+
      2001:db8:1::1/64|      |2001:db8:10::1/32 2001:db8:10::2/32|      |
             +------o-+  R1  +-o-------------------------------o-+  S1  |
+--------+   |        |      |        :     [VMnet3]             |      |
|        |   |        +------+        :                          +------+
| Client +-o-+ [VMnet2]               :
|        |   |        +------+        :                          +------+
+---+----+   |        |      |        :     [VMnet4]             |      | fd02::/64
    :        +------o-+  R2  +-o-------------------------------o-+  S2  +-------
    : 2001:db8:2::1/64|      |2001:db8:20::1/32 2001:db8:20::2/32|      | remote
    :       fd02::1/64+------+                                   +--+---+ local
    :                                                               :     network
    :...............................................................:
        VPN connection (tunnel) to remote local network fd02::/64

                Figure 3. Network configuration in demo with VPN

Tunnel is created by script on both sides (Client and S2).
On client side, tunnel is moved into VPNTEST namespace.
PvD for tunnel is added to pvdman without its involvement in network configuration.

Several PvDs are used in demo. Between them are:
- PvD for local network fd02::/64 (Client + R2)
- PvD for remote local network fd02::/64 (local network behind S2)

Using different PvDs, different networks are used.
This is demonstrated by using same IP address fd02::1 in different PvDs.
When using local PvD, R2 is used, otherwise (remote locale) S2 is used.

Script for demonstration (details in demo-30-00.txt):
- $ sudo ./demo-30-01-C+S2-tunnel.sh create
- $ sudo ./demo-30-02-C-start-pvdman.sh start
- $ sudo ./demo-30-03-C-start-apps.sh


2.2. Mobility

Mobile client can have possibilities for using different connections while at
different places. At home client could use home Wi-Fi, while outdoors it could
use cellular connection through mobile phone (phone could also be a client).

2.2.1. Example from RFC7566: 4.1. A Mobile Node (page 11)

>>>>
                 <----------- Wi-Fi 'Internet' PvD -------->
        +---------+
        | +-----+ |    +-----+         _   __               _  _
        | |Wi-Fi| |    |     |        ( `    )             ( `   )_
        | |-IF  + |----+     |---------------------------(         `)
        | |     | |    |Wi-Fi|      (         )         (  Internet  )
        | +-----+ |    | AP  |     (           )        (            )
        |         |    |     |    (   Service    )      (            )
        |         |    +-----+    (  Provider's   )     (            )
        |         |               (   Networks    -     (            )
        | +----+  |                `_            )      (            )
        | |CELL|  |                 (          )        (            )
        | |-IF +--|-------------------------------------(            )
        | |    |  |                 (_     __)          (_          _)
        | +----+  |                  `- --               `- __  _) -
        +---------+
                 <------- Mobile 'Internet' PvD ----------->

    Figure RFC7566-1: An Example of PvD Use with Wi-Fi and Mobile Interfaces
<<<<
Although Client from Figure 1 have single interface, availability of PvDs from
routers R1 and R2 can simulate presence or absence of Wi-Fi signal.
S1 and S2 represent services on Internet. For this test network from Figure 1
should be modified so that VMnet3 and VMnet4 are connected, represent the same
network (VMnet3).

                                           .....................
                                           :                   :
                        ...................................... :
                        : PvD1 +------+    :        +------+ : :
             (Wi-Fi) +-------o-+  R1  +-o----+----o-+  S1  | : :
                     |  :      +------+    : |      +------+ : :
        +--------+   |  :..................:.|...............: :
        | Client +-o-+ [VMnet2]            : | [VMnet3]        :
        +--------+   |  .....................|................ :
                     |  : PvD2 +------+    : |      +------+ : :
           (CELL-IF) +-------o-+  R2  +-o----+----o-+  S2  | : :
                        :      +------+    :        +------+ : :
                        :..................:.................: :
                                           :    (Internet)     :
                                           :...................:

     Figure 4. Simulating PvD Use with Wi-Fi and Mobile Interfaces

R2 simulate availability of Mobile 'Internet' (which should be always
available), while R1 can simulate Wi-Fi router (which isn't always available).
Enabling and disabling of R1 presence or absence of Wi-Fi can be simulated.

When PvD1 becomes available, all new connections from PvD aware applications
should use it, instead of PvD2 - simulate use Wi-Fi when available.

Scripts:
- demo-20-02-C-pvd-retry.sh (all demo-20* files)
- demo-21-02-C-pvd-retry.sh (all demo-21* files)


2.3. Application preference

When offered multiple connections, a client can choose one depending on
connections' properties.
Most of previous examples can be classified as special cases of this one.
However, here it's up to application to choose PvD that suits her best by
comparing available PvD properties.

                          +------------------------------+
                          | PvD1 +------+       +------+ |
                       +--+----o-+  R1  +-o---o-+  S1  | |
                       |  |      +------+       +------+ |
          +--------+   |  +------------------------------+
          | Client +-o-+
          +--------+   |  +------------------------------+
                       |  | PvD2 +------+       +------+ |
                       +--+----o-+  R2  +-o---o-+  S2  | |
                          |      +------+       +------+ |
                          +------------------------------+

     Figure 2. Simulating PvDs with different properties

Scripts:
- demo-03-01-C-free-Internet-or-else.sh
- demo-20-02-C-pvd-retry.sh


2.4. Multi PvD applications

PvD aware application might need several PvDs simultaneously.
First operation is to choose first PvD and switch to it ("activate it"), prepare
connection (socket). Then activate second PvD and prepare connections and so on.
Each connection should operate normally within its PvD.

Scripts:
- demo-10-01-C-multi-pvd-client-udp.sh
