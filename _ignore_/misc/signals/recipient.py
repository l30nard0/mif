#!/usr/bin/env python

# based on: https://cgit.freedesktop.org/dbus/dbus-python/plain/examples/*

usage = "Usage: python example-signal-recipient.py"

import sys
import traceback

from gi.repository import GLib

import dbus
import dbus.mainloop.glib

#def hello_signal_handler(hello_string):
#	print ("Received signal (by connecting using remote object) and it says: "
#		   + hello_string)

#def catchall_signal_handler(*args, **kwargs):
#	print ("Caught signal (in catchall handler) "
#		   + kwargs['dbus_interface'] + "." + kwargs['member'])
#	for arg in args:
#		print "		" + str(arg)

def catchall_hello_signals_handler(action, pvd_id):
	print "Received a signal: action " + action + " id " + pvd_id

#def catchall_testservice_interface_handler(hello_string, dbus_message):
#	print "org.freedesktop.PvDManager interface says " + hello_string + " when it sent signal " + dbus_message.get_member()


if __name__ == '__main__':
	dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

	bus = dbus.SystemBus()
	#try:
	#   object  = bus.get_object("org.freedesktop.PvDManager","/org/freedesktop/PvDManager")
	#	object.connect_to_signal("stateChanged", hello_signal_handler, dbus_interface="org.freedesktop.PvDManager", arg0="Hello")
	#except dbus.DBusException:
	#	traceback.print_exc()
	#	print usage
	#	sys.exit(1)

	#lets make a catchall
	#bus.add_signal_receiver(catchall_signal_handler, interface_keyword='dbus_interface', member_keyword='member')

	bus.add_signal_receiver(catchall_hello_signals_handler, dbus_interface = "org.freedesktop.PvDManager", signal_name = "stateChanged")

	#bus.add_signal_receiver(catchall_testservice_interface_handler, dbus_interface = "org.freedesktop.PvDManager", message_keyword='dbus_message')

	loop = GLib.MainLoop()
	loop.run()
