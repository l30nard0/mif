/* usage: ./pvd_wait_signal */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <pvd_api.h>

#include <glib.h>
#include <gio/gio.h>

static GMainLoop* loop = NULL;

void pvd_signal_handler ( char *action, char *pvd_id )
{
	printf ( "Received signal with values: %s %s\n", action, pvd_id );
}

int main ( int argc, char *argv[] )
{
	loop = g_main_loop_new (NULL, FALSE);

	if ( pvd_register_signal ( pvd_signal_handler ) == -1 )
		return -1;

	//g_main_loop_run (loop); // or call g_main_context_iteration periodically
	while (1) {
		g_main_context_iteration (NULL, 0);
		sleep (1);
	}

	g_main_loop_unref (loop);

	return 0;
}
