dbus-client: dbus-client.c
	gcc dbus-client.c -o $@ `pkg-config --cflags --libs gobject-2.0 glib-2.0 gio-2.0`

clean:
	@rm -f dbus-client
