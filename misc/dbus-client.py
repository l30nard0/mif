# client

import dbus
import socket

# dbus
bus = dbus.SessionBus()
helloservice = bus.get_object('org.net.pvdman', '/org/net/pvdman')
ping = helloservice.get_dbus_method('ping', 'org.net.pvdman')
print (ping())

# socket
PROTO = socket.AF_INET6
TYPE = socket.SOCK_DGRAM
IF = "lo"
IP = "::1"
PORT = 12345

address = socket.getaddrinfo ( IP, PORT, PROTO, TYPE )
sock = socket.socket ( address[0][0], address[0][1], address[0][2] )
sock.sendto ( b'Hello', address[0][4] )
