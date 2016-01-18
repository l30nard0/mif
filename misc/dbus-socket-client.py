# client (dbus+socket)

import dbus
import socket

# dbus example, for companion dbus-socket-service.py
bus = dbus.SessionBus()
helloservice = bus.get_object('org.freedesktop.PvDManager', '/org/freedesktop/PvDManager')
ping = helloservice.get_dbus_method('ping', 'org.freedesktop.PvDManager')
print (ping("123"))

# dbus example, for pvdman example
"""
bus = dbus.SystemBus()
pvdApiClient = bus.get_object('org.freedesktop.PvDManager', '/org/freedesktop/PvDManager')
getAllPvDs = pvdApiClient.get_dbus_method('getAllPvDs', 'org.freedesktop.PvDManager')
print ( str(getAllPvDs()) )
"""

# socket
PROTO = socket.AF_INET6
TYPE = socket.SOCK_DGRAM
IF = "lo"
IP = "::1"
PORT = 12345

address = socket.getaddrinfo ( IP, PORT, PROTO, TYPE )
sock = socket.socket ( address[0][0], address[0][1], address[0][2] )
sock.sendto ( b'Hello', address[0][4] )
