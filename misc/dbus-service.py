# service example

# better one at https://gist.github.com/caspian311/4676061

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GObject

class MyDBUSService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.net.pvdman', bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/org/net/pvdman')

    @dbus.service.method('org.net.pvdman')
    def ping(self):
        print ( "Got request!" )
        return "Hello from pvdman"

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
myservice = MyDBUSService()
loop = GObject.MainLoop()
loop.run()
