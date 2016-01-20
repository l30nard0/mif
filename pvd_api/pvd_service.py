import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GObject

# TODO create introspection xml file and put it into
# $(datadir)/dbus-1/interfaces (probably /usr/share/dbus-1/interfaces)

# test pvd data
pvds = [
	{"id":"111111", "policy":"111111-policy-data", "data":"111111-other-data", "pids":[] },
	{"id":"222222", "policy":"222222-policy-data", "data":"222222-other-data", "pids":[] },
	{"id":"333333", "policy":"333333-policy-data", "data":"333333-other-data", "pids":[] }
	]

class PvdApiServer ( dbus.service.Object ):
	''' TODO '''
	def __init__(self):
		# using system bus - put pvd-man.conf file into /etc/dbus-1/system.d/
		bus_name = dbus.service.BusName('org.freedesktop.PvDManager', bus=dbus.SystemBus())
		dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/PvDManager')

	@dbus.service.method('org.freedesktop.PvDManager')
	def get_by_id ( self, pvd_id ):
		''' application request specific pvd information, or list of pvds '''
		if pvd_id != "*":
			p = [ pvd for pvd in pvds if str(pvd_id) in pvd["id"] ]
		else: # return all pvds client is allowed for
			p = pvds
		ret = [ ( pvd["id"], pvd["policy"], pvd["data"] ) for pvd in p ]
		return ret

	@dbus.service.method('org.freedesktop.PvDManager')
	def get_by_policy ( self, policy ):
		''' application request specific pvd information, or list of pvds '''
		if len(policy) > 0:
			p = [ pvd for pvd in pvds if str(policy) in pvd["policy"] ]
		else: # return all pvds client is allowed for
			p = pvds
		ret = [ ( pvd["id"], pvd["policy"], pvd["data"] ) for pvd in p ]
		return ret

	@dbus.service.method('org.freedesktop.PvDManager')
	def attach ( self, pvd_id, pid ):
		# application indicates it want to use specific pvd
		p = [ pvd for pvd in pvds if str(pvd_id) == pvd["pvd_id"] ]
		if len(p) != 1:
			return False
		else:
			# mark that process with pid uses pvd_id
			#check if process pid exist (TODO)
			p["pids"].append(pid)
			return True

	@dbus.service.method('org.freedesktop.PvDManager')
	def detach ( self, pvd_id, pid ):
		# application indicates it want to use specific pvd
		p = [ pvd for pvd in pvds if str(pvd_id) == pvd["pvd_id"] ]
		if len(p) != 1:
			return False
		else:
			# mark that process with pid stop using pvd_id
			#check if process pid exist (TODO)
			p["pids"].remove(pid)
			return True

# main loop, dbus initialization
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
apiDBUSResponder = PvdApiServer()

loop = GObject.MainLoop()
loop.run()
