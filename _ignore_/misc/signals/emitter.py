#!/usr/bin/env python

# based on: https://cgit.freedesktop.org/dbus/dbus-python/plain/examples/*


usage = "Usage: python emitter.py"


from gi.repository import GLib

import dbus, dbus.service, dbus.mainloop.glib, time

class TestObject(dbus.service.Object):
    def __init__(self):
		bus_name = dbus.service.BusName('org.freedesktop.PvDManager', bus=dbus.SystemBus())
		dbus.service.Object.__init__(self, bus_name, '/org/freedesktop/PvDManager')

    @dbus.service.signal('org.freedesktop.PvDManager')
    def stateChanged(self, action, pvd_id):
        # The signal is emitted when this method exits
        # You can have code here if you wish
        pass

if __name__ == '__main__':
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    object = TestObject()

    loop = GLib.MainLoop()
    print "Running example signal emitter service."

    while True:
		time.sleep(5)
		object.stateChanged('test', 'id')
