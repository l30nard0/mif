//for testing with dbus-service.py or main.py from pvdman

#include <stdio.h>
#include <gio/gio.h>

int main ()
{
	GDBusConnection *connection;
	GError *error;
	GVariant *value;
	const gchar *greeting_response;
	gchar *greeting;

	error = NULL;

	connection = g_bus_get_sync ( G_BUS_TYPE_SYSTEM, NULL, &error );

	if (connection == NULL)
	{
		g_printerr ("Error connecting to D-Bus: %s\n", error->message);
		g_error_free (error);
		return -1;
	}

	greeting = "Hello";
	value = g_dbus_connection_call_sync (	connection,
											"org.freedesktop.PvDManager", /* bus_name */
											"/org/freedesktop/PvDManager",
											"org.freedesktop.PvDManager",
											"getAllPvDs",
											g_variant_new ("(s)", greeting),
											G_VARIANT_TYPE ("(s)"),
											G_DBUS_CALL_FLAGS_NONE,
											-1,
											NULL,
											&error
										);
	if (value == NULL)
	{
		g_printerr ("Error invoking getAllPvDs(): %s\n", error->message);
		g_error_free (error);
		return -1;
	}
	g_variant_get (value, "(&s)", &greeting_response);
	g_print ("Server said: %s\n", greeting_response);
	g_variant_unref (value);

	g_object_unref(connection);

	return 0;
}

// gcc dbus-client-2.c `pkg-config --cflags --libs gobject-2.0 glib-2.0 gio-2.0`





