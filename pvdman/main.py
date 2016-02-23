
import dbus, threading, time, os
import dbus.service
import dbus.mainloop.glib
from gi.repository import GObject
import socket
import argparse

from pvdman import PvdManager
from ndpclient import NDPClient
from pvdserver import PvdApiServer

def ndp_pending ( fd, cond, ndpc, pvdman ):
	''' Process received RAs '''
	pvdinfos = ndpc.get_pvdinfo()
	if pvdinfos:
		for ( iface, pvdInfo ) in pvdinfos:
			pvdman.setPvd ( iface, pvdInfo )

			# for demo with PvD
			#if "vpn-demo" in pvdInfo.pvd_properties["type"]:
			#	asd

	return True

# check routers
ALIVE_TIMEOUT=10
def pvd_ping ( *args ):
	if pvd_ping.cnt > 0:
		pvdman, ndpc = args
		retry = set()

		# send ping to all routers
		for pvd_key in list(pvdman.pvds):
			phyIfaceName, pvdId = pvd_key
			routerAddress = pvdman.pvds[pvd_key].pvdInfo.routerAddress
			cmd = "ping6 -W 1 -n -q -c 1 -I " + str(phyIfaceName) + " "
			cmd += str(routerAddress) + " 1> /dev/null 2> /dev/null"
			if os.system(cmd) != 0:
				#host not responding
				pvdman.removePvd ( phyIfaceName, pvdId )
				retry.add ( ( phyIfaceName, routerAddress ) )

		# retry with RS
		for phyIfaceName, routerAddress in retry:
			ndpc.send_rs ( iface = phyIfaceName, dest = routerAddress )

	# set timer again
	t = threading.Timer ( ALIVE_TIMEOUT, pvd_ping, args )
	t.daemon = True
	t.start()
	pvd_ping.cnt += 1
pvd_ping.cnt = 0

if __name__ == "__main__":
	# parse command line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument ( '-i', required=False, type=str, help='interface name where to listen for RAs', dest='iface' )
	#parser.add_argument ( '-u', required=False, type=str, help='PvD identifier to ask from radvd', dest='uuid' )
	parser.add_argument ( '--demo', required=False, type=str, help='Activate some demo options' )
	arg = parser.parse_args()

	# create pvdmanager control object
	pvdman = PvdManager()
	print ( "PvdManager Initialized" )
	if arg.demo and arg.demo == "30":
		pvdman.TEST_createPvd()

	# main loop, dbus initialization
	dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
	apiDBUSResponder = PvdApiServer(pvdman)
	print ( "PvdApiServer Initialized" )

	# create ndpclient object and register socket for events
	ndpc = NDPClient( iface = arg.iface )
	sock = ndpc.get_sock ()
	GObject.io_add_watch ( sock.fileno(), GObject.IO_IN, ndp_pending, ndpc, pvdman )
	print ( "NDPClient Initialized" )
	# if interface was given, send RS over that interface (otherwise? sent to all interfaces?)
	if arg.iface:
		ndpc.send_rs ()

	# setup timer for periodic checking of pvds
	if not arg.demo or arg.demo != "30":
		pvd_ping ( pvdman, ndpc )

	# mail loop - wait for events
	loop = GObject.MainLoop()
	loop.run()
