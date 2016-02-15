Demo 1 presentation and discussions

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


1. Network setup

Overall PvD architecture overview is presented in doc/readme.txt.

Network in this demo consists of client node (Client, C in scripts), two
routers R1 and R2 and two servers S1 and S2. Routers and servers have
static address configuration (as shown on Figure 1, set up with demo scripts).
(All nodes in test environment were virtual machines running Lubuntu 15.10.)

For reducing image size prefix 2001:db8 is replaced with P.

                +------------------------------------------------+
                | PvD1                      DNS domain: pvd1.org |
                |           +------+                  +------+   |
                | P:1::1/48 |      | P:10::1  P:10::2 |      |   |
             +--+---------o-+  R1  +-o--------------o-+  S1  |   |
             |  |           |      |                  |      |   |
             |  |           +------+                  +------+   |
+--------+   |  |        www1.pvd1.org              www.pvd1.org |
|        |   |  +------------------------------------------------+
| Client +-o-+
|        |   |  +------------------------------------------------+
+--------+   |  | PvD2                      DNS domain: pvd2.org |
             |  |           +------+                  +------+   |
             |  | P:2::1/48 |      | P:20::1  P:20::2 |      |   |
             +--+---------o-+  R2  +-o--------------o-+  S2  |   |
                |           |      |                  |      |   |
                |           +------+                  +------+   |
                |        www2.pvd2.org              www.pvd2.org |
                +------------------------------------------------+

                Figure 1. Network configuration in demo

Services on hosts:
Client: pvdmanager (pvdman) + custom created applications (testapps)
R1, R2: radvd, DNS server (bind), web server (apache2) + custom apps
S1, S2: DNS server (bind), web server (apache2) + custom apps
Configuration for DNS and web are same for R1 and S1, and for in R2 and S2.

Configuration is setup via scripts. For example for R1:
- R1_conf.sh (R1 settings; settings are saved in environment variables)
- templates: radvd.conf, httpd.conf, bind_append.conf, pvd-zone.db
- run.sh - creates configuration files from templates using settings from
  R1_conf.sh, assign IP addresses to interfaces and starts services afterwards
  (radvd, apache2 and bind9)
Scripts are executed with: sudo ./run.sh <command> <host>
where <command> is one of "start", "stop" and "clean",
while <host> is one of C, R1, R2, S1 and S2.
Command "stop" will stop all started services and applications.
Command "clean" will first invoke "stop" and then restore system to previous
state (remove created configuration files, produced custom logs, compiled
application, temporary files created by services and applications).

For example, services on R1 are started with: sudo ./run.sh start R1


2. What can be demonstrated

2.1. Isolation

Separate PvDs could connect client with only specified destinations, while
all other could be unavailable. For example, different services (servers)
like "internet", "video-on-demand" could be defined through different PvDs
that limit accessibility to only defined services.

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
Using demo from Figure 1, Client can simulate both PC and Set-Top Box with
two applications: one will use PvD1 to reach Internet, while second will use
PvD2 for reaching specific Video-on-Demand Service (Figure 2).

                         +-------------------+
                         | +-----------------+-------------+
                         | | PVD1 +------+   |    +------+ |
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

In simulation only router R1 can be used, or both R1 and R2 could be used (one
for Internet connectivity and other for Video-on-Demand).

Script FIXME started on client FIXME ...

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
After establishing VPN connection separate PvD could be created for VPN.
Private Services accessible through this PvD, possibly using local address,
could even have same addresses as local hosts (connected to the same Home
Gateway). This will not be a problem since applications will run in either
VPN PvD for accessing private services through VPN or in other VPN for
accessing Internet or local hosts.

                         +-------------------+
                         | +-----------------+-------------+
                         | | PVD1 +------+   |    +------+ |
              (Phy-IF) +-+-+----o-+  R1  +-o-+--o-+  S1  | | (Internet)
                       | | |      +------+   |    +------+ |
          +--------+   | | +-----------------+-------------+
          | Client +-o-+ |                   |
          +--------+   | | +-----------------+-------------+
                       | | | PvD2 +------+   |    +------+ |
              (VPN-IF) +-+-+----o-+  R2  +-o-+--o-+  S2  | | (VPN Gateway+
                         | |      +------+   |    +------+ |  Private Services)
                         | +-----------------+-------------+
                         |   (Home Gateway)  |
                         +-------------------+

            Figure 3. Simulating a Node with a VPN Connection

Script FIXME started on client FIXME ...


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
S1 and S2 represent services on Internet. Although S1 is reachable only through
R1 and S2 only through S2 this part of network is behind routers and
"irrelevant" for Client. In similar network setup, S1 (and/or S2) could be
connected to both R1 and R2. Then simulation will be more like in presented
example even on "Internet" side.

                                           +--------------+
                        +------------------+------------+ |
                        | PVD1 +------+    |   +------+ | |
             (Wi-Fi) +--+----o-+  R1  +-o--+-o-+  S1  | | |
                     |  |      +------+    |   +------+ | |
        +--------+   |  +------------------+------------+ |
        | Client +-o-+                     |              |
        +--------+   |  +------------------+------------+ |
                     |  | PvD2 +------+    |   +------+ | |
           (CELL-IF) +--+----o-+  R2  +-o--+-o-+  S2  | | |
                        |      +------+    |   +------+ | |
                        +------------------+------------+ |
                                           |  (Internet)  |
                                           +--------------+

     Figure 4. Simulating PvD Use with Wi-Fi and Mobile Interfaces

R2 simulate availability of Mobile 'Internet' (which should be always
available), while R1 can simulate Wi-Fi router (which isn't always available).
Enabling and disabling of R1 interface with IP address P:1::1/48 presence or
absence of Wi-Fi can be simulated.

When PvD1 becomes available, all new connections from PvD aware applications
should use it, instead of PvD2 - simulate use Wi-Fi when available.

>>> TODO
For connections in progress there are several possibilities.
1. Connections can be managed by MIF-pvdmanager: when more favorable PvD
   becomes available, less favorable can be disabled. For example, when Wi-Fi
   becomes available, Mobile 'Internet' PvD (PvD2) will be disabled and all
   applications which use it will fail and will have to reconnect through new
   PvD (PvD1 = Wi-Fi).
2. Connections can be managed by application: application will be notified that
   more favorable connection (PvD1) become available. It will be up to the
   application to break current connection and reestablish a new one over new
   PvD (Wi-Fi).
<<< TODO

Script FIXME started on client FIXME ...


2.3. Application preference

When offered multiple connections, a client can choose one depending on
connections' properties. Connection preference is up to client application
or system policy for that application. In former case, application must
be launched by special launcher which will chose appropriate connection (PvD)
for specific client.
Most of previous examples can be classified as special cases of this one.
However, here its up to application to choose PvD that suits her best by
comparing available PvD properties.
Example properties used here are just that "example properties", not to be
taken as something that should be used in some specification.

                          +------------------------------+
                          | PVD1 +------+       +------+ |
                       +--+----o-+  R1  +-o---o-+  S1  | |
                       |  | PVD3 +------+       +------+ |
          +--------+   |  +------------------------------+
          | Client +-o-+
          +--------+   |  +------------------------------+
                       |  | PvD2 +------+       +------+ |
                       +--+----o-+  R2  +-o---o-+  S2  | |
                          | PvD4 +------+       +------+ |
                          +------------------------------+

     Figure 2. Simulating PvDs with different properties

Script FIXME started on client FIXME ...
