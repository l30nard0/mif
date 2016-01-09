# client

import dbus

bus = dbus.SessionBus()
helloservice = bus.get_object('org.net.pvdman', '/org/net/pvdman')
ping = helloservice.get_dbus_method('ping', 'org.net.pvdman')
print (ping())
