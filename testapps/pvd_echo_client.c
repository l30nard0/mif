/*
 * MIF application that use "best" PvD to reach server on "internet".
 * When better become available use it. When current become unreachable, use
 * next one.
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
#include <pvd_api.h>

#define MAXBUF      32
#define ITER        200
#define ITER_RETRY  15

#define PREF1 "{\"type\":\"internet\", \"pricing\":\"free\"}"
#define PREF2 "{\"type\":\"internet\"}"

static char *pvd_prefs[] = { PREF1, PREF2, NULL };

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
	int sock, size, i, iter, iter2;
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

	/* send echo ITER times */
	sock = -1;
	i = -1;
	iter = 1;
	iter2 = 0;
	while ( iter <= ITER )
	{
		if ( sock == -1 ) {
			pvd_reset();
			while (1) { // ; pvd_prefs[i] != 0; i++ ) {
				if ( t == time(NULL) ) {
					fprintf ( stderr, "Trying next ...\n" );
					sleep(1);
				}
				t = time(NULL);
				i++;
				if ( pvd_prefs[i] == NULL )
					i = 0; //restart from beginning
				pvd = pvd_get_by_properties ( pvd_prefs[i] );
				if (!pvd)
					return -1; //error connecting to dbus service
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
			if ( i == 0 )
				iter2 = 0;
		}

		size = sendto ( sock, &out_buf, strlen(out_buf)+1, 0, server, len );
		if ( size < 0 ) { perror ("sendto"); return -1; }

		sleep(1);

		size = recv ( sock, in_buf, MAXBUF, MSG_DONTWAIT );
		if ( size < 0 ) {
			perror("S:recvfrom");
			close ( sock );
			sock = -1;
			fprintf ( stderr, "Retrying...\n" );
		}
		else {
			printf ( "%d using %s %s", iter, pvd[0]->ns, pvd_prefs[i] );
			list_all_pvds();

			iter++;
			if ( i > 0 ) { //not best connection
				iter2++;
				if ( iter2 >= ITER_RETRY ) { //retry with best connection
					close(sock);
					sock = -1;
					iter2 = 0;
				}
			}
		}
	}
	close (sock);

	return 0;
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