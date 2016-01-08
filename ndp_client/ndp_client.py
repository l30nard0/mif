import socket, select, struct, sys, binascii

def icmpv6_socket ( iface = None ):
	sock = socket.socket ( socket.AF_INET6, socket.SOCK_RAW, socket.IPPROTO_ICMPV6 )
	#sock.setblocking ( False )
	sock.setsockopt ( socket.IPPROTO_IPV6, socket.IPV6_RECVPKTINFO, 1 )
	sock.setsockopt ( socket.IPPROTO_IPV6, socket.IPV6_MULTICAST_HOPS, 255 )
	if iface:
		sock.setsockopt ( socket.SOL_SOCKET, 25, bytes(iface, 'UTF-8') )
	return sock

def icmpv6_recvmsg ( sock, timeout=0 ):
	( r, w, x ) = select.select ( [sock], [], [], timeout )
	if not r:
		return None
	(packet, ancdata, msg_flags, address) = sock.recvmsg ( 1024, 1024 )
	# packet = NDP packet
	# address = (host, port, flowinfo, scopeid)
	src = address[0].split("%")[0]
	dest = None
	iface = address[3]
	# ancdata = (cmsg_level, cmsg_type, cmsg_data)
	# cmsg_data =  struct in6_pktinfo{ struct in6_addr ipi6_addr; int ipi6_ifindex;}
	for (cmsg_level, cmsg_type, cmsg_data) in ancdata:
		if cmsg_level == socket.IPPROTO_IPV6 and cmsg_type == socket.IPV6_PKTINFO and cmsg_data:
			dest = socket.inet_ntop ( socket.AF_INET6, cmsg_data[:-4] )
			iface = int.from_bytes(cmsg_data[-4:], byteorder=sys.byteorder)
			break
	if test_checksum ( src, dest, len(packet), 58, packet ):
		return ndp_packet( packet, src, dest, socket.if_indextoname(iface) )
	else:
		#log error
		print("checksum failed")
		return None

def icmpv6_sendmsg ( sock, msg, iface=0 ):
	sock.sendto ( msg.packet, ( msg.dest, 0, 0, socket.if_nametoindex(iface) ) )

def checksum ( src, dest, length, next_header, packet ):
	p =  socket.inet_pton(socket.AF_INET6, src)
	p += socket.inet_pton(socket.AF_INET6, dest)
	p += struct.pack("!LBBBB", length, 0,0,0, next_header ) + packet
	csum = 0
	for i in range(0, len(p), 2):
		csum += int.from_bytes(p[i:i+2], byteorder="big")
	while csum > 1<<16:
		csum = (csum>>16) + (csum&0xffff)
	return csum

def test_checksum ( src, dest, length, next_header, packet ):
	return checksum ( src, dest, length, next_header, packet ) == 0xffff

class ndp_packet:
	TYPE_RS = 133
	TYPE_RA = 134
	OPT_SRC_LLA = 1
	OPT_TARG_LLA = 2
	OPT_PREFIX = 3
	OPT_REDIRECT = 4
	OPT_MTU = 5
	OPT_PVD_CO = 63
	OPT_PVD_ID = 31

	def __init__ (self, packet=None, src=None, dest=None, iface=None ):
		self.Type = None
		self.Code = None
		self.Checksum = None
		self.packet = packet
		self.src = src
		self.dest = dest
		self.iface = iface
		self.options = []

		if self.packet:
			self.unpack()

	def create_rs ( self, uuid = None ):
		self.Type = ndp_packet.TYPE_RS
		self.Code = 0
		self.options = []
		if uuid:
			opt = {}
			opt['type'] = ndp_packet.OPT_PVD_ID
			opt['uuid'] = uuid
			opt['pvd_id'] = uuid
			self.options.append(opt)
		self.pack()
		return self.packet

	def pack ( self ):
		packet = None
		if not self.src or not self.dest: # required for checksum
			return None
		if self.Type == ndp_packet.TYPE_RS:
			packet = struct.pack("BBHI", self.Type, self.Code, 0, 0 )
			for opt in self.options:
				if opt['type'] == ndp_packet.OPT_PVD_ID:
					pvd_id_type = 1
					pvd_id_uuid = bytes ( opt['uuid'], 'utf-8' )
					pvd_id_len = len(pvd_id_uuid)
					opt['data'] = struct.pack("BB", pvd_id_type, pvd_id_len )
					opt['data'] += pvd_id_uuid
					opt_len = 2 + ( 2 + pvd_id_len )
					pad_len = ((opt_len+7)//8)*8 - opt_len
					opt['data'] += (b'\0')*pad_len #bytes ( "\0"*pad_len, 'utf-8' )
					opt['len'] = (2 + ( 2 + len(opt['data']) ))//8

				packet += struct.pack("BB", opt['type'], opt['len'] )
				packet += opt['data']
		self.packet = packet
		if self.packet:
			#set checksum
			self.Checksum = checksum ( self.src, self.dest, len(self.packet), 58, self.packet )
			self.packet = self.packet[0:2] + struct.pack ( "!H", self.Checksum ) + self.packet[4:]

		return self.packet

	def unpack ( self ):
		p = self.packet
		options = b''
		(self.Type, self.Code, self.Checksum) = struct.unpack("!BBH", p[0:4])
		if self.Type == ndp_packet.TYPE_RA:
			(self.Hop_Limit, MO, self.Router_Lifetime, self.Reachable_Time,
			 self.Retrans_Timer) = struct.unpack("!BBHII", p[4:16])
			self.M = ( MO & 0x80 ) != 0
			self.O = ( MO & 0x40 ) != 0
			if len(p) > 16:
				options = p[16:]
		elif self.Type == ndp_packet.TYPE_RS:
			if len(p) > 8:
				options = p[8:]
		else:
			return #Not ndp packet of type: RA or RS!
		self.unpack_options ( self.options, options )

	def unpack_options ( self, save_to, options ):
		''' Unpack options from raw form 'options' to list 'save_to' '''
		# each unpacked options have: type, len, raw 'data' and formated data
		# which is named per option type (e.g. for OPT_MTU => name is 'mtu')
		while options:
			opt={}
			opt['type'] = options[0]
			opt['len'] = options[1]
			opt['data'] = options[2:opt['len']*8]
			options = options[options[1]*8:]
			if opt['type'] == ndp_packet.OPT_SRC_LLA:
				opt['src_lla'] = opt['data']
			elif opt['type'] == ndp_packet.OPT_TARG_LLA:
				opt['targ_lla'] = opt['data']
			elif opt['type'] == ndp_packet.OPT_PREFIX:
				opt['prefix_len'] = opt['data'][0]
				opt['L'] = ( opt['data'][1] & 0x80 ) != 0
				opt['A'] = ( opt['data'][1] & 0x40 ) != 0
				opt['valid_lifetime'] = struct.unpack("!I", opt['data'][2:6])[0]
				opt['prefered_lifetime'] = struct.unpack("!I", opt['data'][6:10])[0]  
				opt['prefix'] = socket.inet_ntop ( socket.AF_INET6, opt['data'][14:])
			elif opt['type'] == ndp_packet.OPT_REDIRECT:
				pass # don't process this option (for now)
			elif opt['type'] == ndp_packet.OPT_MTU:
				opt['mtu'] = struct.unpack("!I", opt['data'][2:6])
			elif opt['type'] == ndp_packet.OPT_PVD_CO:
				# 0000000000001f05042466303337656136322d656534662d343465342d383235632d313666326635636339623366030440e000015180000038400000000020011111111111110000000000000000030440e000015180000038400000000020012222222222220000000000000000030440e000015180000038400000000020013333333333330000000000000000
				opt['S'] = ( (opt['data'][0] & 0x80 ) != 0 )
				opt['Name_Type'] = opt['data'][1]
				if opt['S']:
					#opt['key_hash'] = opt['data][2:18]
					#must proces signature for length ..
					#container = opt['data'] + skip hash and signature
					pass
				else:
					container = opt['data'][6:]
				opt['options'] = []
				self.unpack_options ( opt['options'], container )
			elif opt['type'] == ndp_packet.OPT_PVD_ID:
				#pass
				opt['pvd_id'] = (opt['data'][2:]).decode("utf-8")
			else:
				#don't process unknown options
				pass
			save_to.append(opt)

	def dump(self):
		s = "src:"+str(self.src)+"\ndest:"+str(self.dest)
		if self.iface:
			s += "\niface="+self.iface
		s += "\nNDP:"
		if self.Type == ndp_packet.TYPE_RA:
			s += "\n\tMessage Type: Router Advertisement message"
		elif self.Type == ndp_packet.TYPE_RS:
			s += "\n\tMessage Type: Router Solicitation message"
		s += "\n\tType:"+str(self.Type)+"\n\tCode:" + str(self.Code)
		if self.Type == ndp_packet.TYPE_RA:
			s += "\n\tCur Hop Limit:" + str(self.Hop_Limit)
			s += "\n\tM:" + str(self.M)
			s += "\n\tO:" + str(self.O)
			s += "\n\tRouter Lifetime:" + str(self.Router_Lifetime)
			s += "\n\tReachable Time:" + str(self.Reachable_Time)
			s += "\n\tRetrans Timer:" + str(self.Retrans_Timer)
			s += "\n\tRouter Lifetime:" + str(self.Router_Lifetime)
		s += self.dump_options ( self.options )
		return s

	def dump_options ( self, options ):
		s = ""
		for opt in options:
			s += "\n\toption: "
			if opt['type'] == ndp_packet.OPT_PVD_ID:
				s += "OPT_PVD_ID " + str(opt['pvd_id']) + "\n"
			elif opt['type'] == ndp_packet.OPT_SRC_LLA:
				s += "Source Link-layer Address:" + "\n\t\t"
				s += binascii.hexlify ( opt['data'] ).decode('utf-8')
			elif opt['type'] == ndp_packet.OPT_TARG_LLA:
				s += "Target  Link-layer Address:" + "\n\t\t"
				s += binascii.hexlify ( opt['data'] ).decode('utf-8')
			elif opt['type'] == ndp_packet.OPT_PREFIX:
				s += "OPT_PREFIX " + "\n\t\t"
				s += "prefix_len:" + str(opt['prefix_len']) + "\n\t\t"
				s += "L:" + str(opt['L']) + "\n\t\t"
				s += "A:" + str(opt['A']) + "\n\t\t"
				s += "valid_lifetime:" + str(opt['valid_lifetime']) + "\n\t\t"
				s += "prefered_lifetime:" + str(opt['prefered_lifetime']) + "\n\t\t"
				s += "prefix:" + str(opt['prefix']) + "\n"
			elif opt['type'] == ndp_packet.OPT_PVD_CO:
				s += "OPT_PVD_CO start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>" + "\n\t\t"
				s += self.dump_options ( opt['options'] )
				s += "\n\toption: OPT_PVD_CO end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" + "\n"
			else:
				s += "(raw) " + str(opt['type']) +" " + str(opt['len']) + " "
				s += binascii.hexlify ( opt['data'] ).decode('utf-8') #str(opt['data'])
		return s

class ndp_client:
	ALL_ROUTERS = "ff02::2"
	def __init__ ( self, sock=None, iface = None ):
		self.sock = sock
		self.iface= iface
		if not self.sock:
			self.sock = icmpv6_socket(self.iface)

	def recvmsg ( self, timeout = 0 ):
		return icmpv6_recvmsg ( self.sock, timeout )

	def send_rs ( self, src, uuid, dest = None ):
		if not dest:
			dest = ndp_client.ALL_ROUTERS
		packet = ndp_packet ( src = src, dest = dest, iface=self.iface )
		pack_raw = packet.create_rs(uuid)
		icmpv6_sendmsg ( self.sock, packet, self.iface )
		return packet


# print ( "Usage: " + sys.argv[0] + " [iface [host-link-local-address [uuid-to-request]]]" )
iface = None
if len(sys.argv) > 1:
	iface = sys.argv[1] #socket.if_nametoindex(sys.argv[1])

ndpc = ndp_client(iface=iface)

if len(sys.argv) > 2:
	lla = sys.argv[2]
	if len(sys.argv) > 3:
		uuid = sys.argv[3]
	else:
		uuid = None
	sent = ndpc.send_rs ( src=lla, uuid=uuid )
	print("\nSent:")
	print(sent.dump())

received = ndpc.recvmsg(timeout=30)
if received:
	print("\nReceived:")
	print(received.dump())


# listen for first ndp packet on eth1:
# sudo python3 ndp_client.py eth1

# send Router Solicitation message
# (source ipv6 link local address: fe80::20c:29ff:fe6e:bb21)
# sudo python3 ndp_client.py eth1 fe80::20c:29ff:fe6e:bb21

# send Router Solicitation message
# (source ipv6 link local address: fe80::20c:29ff:fe6e:bb21)
# (uuid of pvd to request: aff6ed92-b4a1-11e5-9f22-ba0be0483c18)
# sudo python3 ndp_client.py eth1 fe80::20c:29ff:fe6e:bb21 aff6ed92-b4a1-11e5-9f22-ba0be0483c18
