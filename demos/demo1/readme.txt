Demo 01
========
(Overview of services used on nodes is described in doc/readme.txt)

Network:
--------

+--------+                      +------+                                +------+
|        |     2001:db8:1::1/48 |      | 2001:db8:10::1  2001:db8:10::2 |      |
| Client +-o-+----------------o-+  R1  +-o----------------------------o-+  S1  |
|        |   |                  |      |                                |      |
+--------+   |                  +------+                                +------+
             |
             |                  +------+                                +------+
             | 2001:db8:2::1/48 |      | 2001:db8:20::1  2001:db8:20::2 |      |
             +----------------o-+  R2  +-o----------------------------o-+  S2  |
                                |      |                                |      |
                                +------+                                +------+

PvDs:
-----
R1-PVD1: 2001:db8:1:1::/64 (implicit) { "type": ["internet", "wired"],    "bandwidth":"10 Mbps", "pricing":"free" }
R1-PVD2: 2001:db8:1:2::/64 (explicit) { "type": ["iptv", "wired"],        "bandwidth":"10 Mbps", "pricing":"free" }
R2-PVD1: 2001:db8:2:1::/64 (implicit) { "type": ["internet", "cellular"], "bandwidth":"1 Mbps",  "pricing":"0,01 $/MB" }
R2-PVD2: 2001:db8:2:2::/64 (explicit) { "type": ["voice", "cellular"],    "bandwidth":"1 Mbps",  "pricing":"0,01 $/MB" }

Expected behavior:
- default gateway for R1-PVD1 and R1-PVD2 is R1
- default gateway for R2-PVD1 and R2-PVD2 is R2
- S1 isn't reachable over R2-PVD1 and R2-PVD2
- S2 isn't reachable over R1-PVD1 and R1-PVD2
- public address of R1 isn't reachable over R2-PVD1 and R2-PVD2
- public address of R2 isn't reachable over R1-PVD1 and R1-PVD2


Test setup:
-----------
On each node, from conf/tc01/ run:
$ sudo ./run start <node-name>
For example, on router R1:
$ sudo ./run start R1

For stopping services:
$ sudo ./run stop <node-name>

For cleaning log files, added configuration files, temporary files:
$ sudo ./run clean <node-name>

On client node, after "sudo ./run start C", applications can be started from client_api/tests:
(from git root)
$ cd client_api/tests
$ make
$ ./pvd_list
$ sudo ./pvd_run <pvd-id> command


Example executions on client side, after all routers and servers were started
------------------------------------------------------------------------------

List available PvDs
+++++++++++++++++++

$ ./pvd_list
Requesting all (*):
id: c79b1614-66bf-e259-82b0-807aaed34c17 ns:mifpvd-1 iface:eno33554984
properties: {"bandwidth": "1 Mbps", "type": ["internet", "cellular"], "name": "Cellular internet access", "id": "implicit", "pricing": "0,01 $/MB"}

id: f037ea62-ee4f-44e4-825c-16f2f5cc9b3e ns:mifpvd-2 iface:eno33554984
properties: {"bandwidth": "0,1 Mbps", "type": ["voice", "cellular"], "name": "Phone", "id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3e", "pricing": "0,01 $/MB"}

id: cfe25073-4d60-6f0b-d88f-1003c82a1817 ns:mifpvd-3 iface:eno33554984
properties: {"bandwidth": "10 Mbps", "type": ["internet", "wired"], "name": "Home internet access", "id": "implicit", "pricing": "free"}

id: f037ea62-ee4f-44e4-825c-16f2f5cc9b3f ns:mifpvd-4 iface:eno33554984
properties: {"bandwidth": "10 Mbps", "type": ["iptv", "wired"], "name": "TV", "id": "f037ea62-ee4f-44e4-825c-16f2f5cc9b3f", "pricing": "free"}

----
Order of pvds are determined by order of RAs MIF component received first.
In previous case, first to arrive were RAs of router R2 (not R1).
Therefore, mifpvd-1 and mifpvd-2 are provided by R2, others by R1.
----


Running commands in PvD given by PvD-Id
++++++++++++++++++++++++++++++++++++++
Lets try to reach S1 and S2 from mifpvd-1 (c79b1614-66bf-e259-82b0-807aaed34c17)

----
$ sudo ./pvd_run c79b1614-66bf-e259-82b0-807aaed34c17 wget http://[2001:db8:10::2]/index.html
Activating pvd: c79b1614-66bf-e259-82b0-807aaed34c17:
pvd c79b1614-66bf-e259-82b0-807aaed34c17 activated!
Executing: wget http://[2001:db8:10::2]/index.html
--2016-02-12 00:02:40--  http://[2001:db8:10::2]/index.html
Connecting to [2001:db8:10::2]:80... failed: Network is unreachable.

$ sudo ./pvd_run c79b1614-66bf-e259-82b0-807aaed34c17 wget http://[2001:db8:20::2]/index.html
Activating pvd: c79b1614-66bf-e259-82b0-807aaed34c17:
pvd c79b1614-66bf-e259-82b0-807aaed34c17 activated!
Executing: wget http://[2001:db8:20::2]/index.html
--2016-02-12 00:03:19--  http://[2001:db8:20::2]/index.html
Connecting to [2001:db8:20::2]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 17 [text/html]
Saving to: ‘index.html’

index.html  100%[=====================================>] 17  --.-KB/s in 0s

2016-02-12 00:03:19 (2,53 MB/s) - ‘index.html’ saved [17/17]

$ cat index.html
Web server on S2
----

Comment:
S2 is reachable over mifpvd-1 and mifpvd-2, S1 over mifpvd-3 and mifpvd-4.
----

Running commands in PvD given by properties
++++++++++++++++++++++++++++++++++++++++++

$ sudo ./pvd_prop_run "{\"type\":\"internet\",\"pricing\":\"free\"}" firefox http://[2001:db8:10::2]/swtrailer.mp4

Comment:
If PvDs with such properties exists, chose first and use it to run give command.
If such PvD doesn't exist print error and exit.

Choose command depending on available PvDs
++++++++++++++++++++++++++++++++++++++++++

$ sudo ./pvd_fallback_example.sh

Script tries first to use PvD which has both "internet" and "free" properties.
If such PvD is available an example movie is streamed from S1 (over R1).
If such PvD isn't available an example audio file is streamed from S2 (over R2).

To demonstrate this feature, first stop R1 (shut down or just stop services and
disable interface which connects to client). After an timeout client will
detect that R1 is unavailable and remove all PvDs that were obtained by R1.
If pvd_fallback_example.sh is started now, PvD is chosen from ones offered by R2,
but since those PvD aren't "free" other action is performed (movie is not
played, rather, audio is streamed.
If R1 is then restarted and pvd_fallback_example.sh started again it should
stram movie from S1 (over R1).


Using two PvDs simultaneously from single application
+++++++++++++++++++++++++++++++++++++++++++++++++++++

First, start echo_server on S1 and S2 (it should start automatically with run.sh).

$ sudo ./multi_pvd_echo_client \
  cfe25073-4d60-6f0b-d88f-1003c82a1817 2001:db8:10::2 20000 \
  c79b1614-66bf-e259-82b0-807aaed34c17 2001:db8:20::2 20000
12121212

Client opens two UDP sockets, each in its PvD:
- 1st one will go to S1 through R1 (since R1 is default gateway for 1st PVD)
- 2nd one will go to S2 through R2 (since R2 is default gateway for 2nd PVD)

Program will send "1" to S1 and "2" to S2. If echo is received its printed.


DNS names
---------
DNS server is started on R1, R2, S1 and S2.
R1 and S1 have names for www.pvd1.org => S1, www1.pvd1.org => R1
R2 and S2 have names for www.pvd2.org => S2, www1.pvd2.org => R2
IP addresses from previous examples can be replaced with names.
