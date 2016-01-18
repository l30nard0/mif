# service example (dbus+socket)

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GObject
import socket

PROTO = socket.AF_INET6
TYPE = socket.SOCK_DGRAM
IF = "lo"
IP = "::1"
PORT = 12345

address = socket.getaddrinfo ( IP, PORT, PROTO, TYPE )
sock = socket.socket ( address[0][0], address[0][1], address[0][2] )
sock.bind ( address[0][4] )

def sock_received ( fd, cond, src_socket ):
	(data, addr ) = src_socket.recvfrom ( 1024 )
	print(data)
	print(addr)
	return True

class MyDBUSService(dbus.service.Object):
    def __init__(self):
		# using session bus
        bus_name = dbus.service.BusName('org.freedesktop.PvDManager', bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/PvDManager')

    @dbus.service.method('org.freedesktop.PvDManager')
    def ping ( self, msg ):
        print ( "Got request!" + str(msg) )
        return "Hello from pvdman"

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
myservice = MyDBUSService()

GObject.io_add_watch ( sock.fileno(), GObject.IO_IN, sock_received, sock )

loop = GObject.MainLoop()
loop.run()
