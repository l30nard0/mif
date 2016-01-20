PROG = pvd_api

pvd_api: pvd_api.c
	gcc $< -o $@ `pkg-config --cflags --libs gobject-2.0 glib-2.0 gio-2.0`

clean:
	@-rm -f $(PROG)
