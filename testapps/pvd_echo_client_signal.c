/*
 * MIF application that use "best" PvD to reach server on "internet".
 * When better become available use it.
 *
 * usage: pvd_echo_client server port
 *
 * example:
 * $ sudo ./pvd_echo_client 2001:db8:10::2 20000
 * $ sudo ./pvd_echo_client fe80::20c:29ff:fe16:a042%eno16777736 20000
 */

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <sys/time.h>
#include <sys/times.h>
#include <signal.h>
#include <time.h>
#include <glib.h>
#include <gio/gio.h>
#include <pvd_api.h>

#define MAXBUF      32
#define ITER        200
#define ITER_RETRY  15

#define PREF1 "{\"type\":\"internet\", \"pricing\":\"free\"}"
#define PREF2 "{\"type\":\"internet\"}"

static char *pvd_prefs[] = { PREF1, PREF2, NULL };
static GMainLoop* loop = NULL;
static int retry = 0;

void pvd_signal_handler ( char *action, char *pvd_id )
{
	printf ( "Received signal with values: %s %s\n", action, pvd_id );
	retry = 1;
}

static int open_socket (char *host, char *port, struct sockaddr **addr, socklen_t *len)
{
	struct addrinfo hints, *res, *ressave;
	int sockfd, status;

	bzero ( &hints, sizeof(struct addrinfo) );
	hints.ai_flags = AI_PASSIVE;
	hints.ai_family = AF_UNSPEC; //AF_INET6;
	hints.ai_socktype = SOCK_DGRAM;
	hints.ai_protocol = IPPROTO_UDP;

	if ( ( status = getaddrinfo ( host, port, &hints, &res ) ) != 0 ) {
		perror ("getaddrinfo");
		return -1;
	}
	ressave = res;
	while (res) {
		sockfd = socket ( res->ai_family, res->ai_socktype, res->ai_protocol );
		if ( sockfd >= 0 )
			break;
		res = res->ai_next;
	}
	if ( sockfd < 0 ) {
		fprintf ( stderr, "Can't create socket for remote: %s %s\n", host, port );
		return -1;
	}
	*len = res->ai_addrlen;
	*addr = malloc(res->ai_addrlen);
	memcpy ( *addr, res->ai_addr, res->ai_addrlen );
	freeaddrinfo ( ressave );

	return sockfd;
}

static void list_all_pvds ();

int main ( int argc, char **argv )
{
	char in_buf[MAXBUF], out_buf[]="1";
	int sock = -1, size, i, iter = 1;
	socklen_t len;
	struct sockaddr *server;
	char *host, *port, *pvd_id;
	struct pvd **pvd;
	time_t t = (time_t) 0;

	if ( argc != 3 ) {
		printf ( "usage: pvd_echo_client <remote-address> <remote-port>\n" );
		return -1;
	}
	host = argv[1]; port = argv[2];

	loop = g_main_loop_new (NULL, FALSE);
	if ( pvd_register_signal ( pvd_signal_handler ) == -1 )
		goto return_error;

	/* send echo ITER times */
	while ( iter <= ITER )
	{
		if ( sock == -1 || retry ) {
			for ( i = 0; pvd_prefs[i] != 0; i++ ) {
				if ( t == time(NULL) ) {
					fprintf ( stderr, "Trying next ...\n" );
					sleep(1);
				}
				t = time(NULL);

				pvd = pvd_get_by_properties ( pvd_prefs[i] );
				if (!pvd)
					goto return_error; //error connecting to dbus service
				if ( !pvd[0] || pvd[0]->id[0] == 0 )
					continue; //no such pvd

				pvd_id = pvd[0]->id;
				if ( pvd_activate ( pvd_id, getpid() ) == -1 )
					continue; //pvd activation error !!?
				break; //swiched to requested pvd
			}
			sock = open_socket ( host, port, &server, &len );
			if ( sock == -1 ) {
				fprintf ( stderr, "Open socket error for pvd %s. Retrying...\n",
					pvd[0]->ns
				);
				continue;
			}

			printf ( "Connected with properties %s to %s\n",
				pvd_prefs[i], pvd[0]->ns );

			retry = 0;
		}

		size = sendto ( sock, &out_buf, strlen(out_buf)+1, 0, server, len );
		if ( size < 0 ) {
			perror("sendto");
			close ( sock );
			sock = -1;
			fprintf ( stderr, "Retrying...\n" );
			continue;
		}

		g_main_context_iteration (NULL, 0);
		sleep(1);

		size = recv ( sock, in_buf, MAXBUF, MSG_DONTWAIT );
		if ( size < 0 ) {
			perror("recvfrom");
			close ( sock );
			sock = -1;
			fprintf ( stderr, "Retrying...\n" );
		}
		else {
			printf ( "%d using %s %s", iter, pvd[0]->ns, pvd_prefs[i] );
			list_all_pvds();

			iter++;
		}
	}
	close (sock);
	g_main_loop_unref (loop);
	return 0;

return_error:
	if ( sock != -1 )
		close (sock);
	g_main_loop_unref (loop);
	return 1;
}

static void list_all_pvds ()
{
	int i = 0;
	struct pvd **pvd;

	pvd = pvd_get_by_id ( "*" );
	if (!pvd)
		return; //error connecting to dbus service

	printf ( " (pvds in system:" );
	for (i = 0; pvd[i] != NULL; i++) {
		printf (" %s", pvd[i]->ns );
		free(pvd[i]->id);
		free(pvd[i]->ns);
		free(pvd[i]->iface);
		free(pvd[i]->properties);
		free(pvd[i]);
	}
	free(pvd);
	printf ( ")\n" );
}