import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GObject

class PvdApiServer ( dbus.service.Object ):
	''' TODO '''
	def __init__(self):
		# using system bus - put pvd-man.conf file into /etc/dbus-1/system.d/
		bus_name = dbus.service.BusName('org.freedesktop.PvDManager', bus=dbus.SystemBus())
		dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/PvDManager')

	@dbus.service.method('org.freedesktop.PvDManager')
	def getAllPvDs ( self, *argv ):
		print ( "Got request: " + " ".join (argv) )
		return "Hello to you too"

# main loop, dbus initialization
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
apiDBUSResponder = PvdApiServer()

loop = GObject.MainLoop()
loop.run()
