import dbus
import dbus.service
from pvdman import PvdManager

# TODO create introspection xml file and put it into
# $(datadir)/dbus-1/interfaces (probably /usr/share/dbus-1/interfaces)

# test pvd data
testpvds = [
	("pvd-id-wired-0", "default", "eth0" ),
	("pvd-id-wired-1", "test", "eth1" ),
	("pvd-id-loopback", "default", "lo" )
]
empty_pvd = ("", "", "")

class PvdApiServer ( dbus.service.Object ):
	''' TODO '''
	def __init__(self, pvdman=None):
		self.pvdman = pvdman
		# using system bus - put pvd-man.conf file into /etc/dbus-1/system.d/
		bus_name = dbus.service.BusName('org.freedesktop.PvDManager', bus=dbus.SystemBus())
		dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/PvDManager')

	def __get_pvds (self):
		if self.pvdman:
			return self.pvdman.getPvds()
		else: #test only!
			return testpvds

	@dbus.service.method('org.freedesktop.PvDManager')
	def get_by_id ( self, pvd_id ):
		''' application request specific pvd information, or list of pvds '''
		pvds = self.__get_pvds ()

		if pvd_id != "*":
			p = [ pvd for pvd in pvds if str(pvd_id) in pvd[0] ]
		else: # return all pvds client is allowed for
			p = pvds
		if not p:
			p = [empty_pvd]

		return p

	@dbus.service.method('org.freedesktop.PvDManager')
	def activate ( self, pvd_id, pid ):
		''' return pvd information for that specific pvd '''
		pvds = self.__get_pvds ()
		p = [ pvd for pvd in pvds if str(pvd_id) == pvd[0] ]
		if len(p) == 1:
			p = p[0]
		else:
			p = empty_pvd

		# TODO save pid with pvd/namespace

		return p



# for test only! (included from main.py)
if __name__ == "__main__":
	import dbus.mainloop.glib
	from gi.repository import GObject

	# main loop, dbus initialization
	dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
	apiDBUSResponder = PvdApiServer()

	loop = GObject.MainLoop()
	print("PvdApiServer running")
	loop.run()
