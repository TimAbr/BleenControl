;Client.YourIP    db '127.000.000.001', 0
Client.YourIP    db '192.168.1.11', 0, 0, 0
Client.YourPort  dd 1234
Client.YourP2PPort  dd 1111

HOST   = 0
PLAYER = 1

Client.MSGTCPInit           dd 7
Client.MSGUDPInit           dd 8

Client.SizeWorldBuffer      dd ?

testUDPLine db 'Hello', 0

Client.ReadBuffer db 150 dup(0)
Client.SizeBuffer dd $ - Client.ReadBuffer

Client.IPPROTO_UDP = 17
Client.IPPROTO_TCP = 6
Client.INADDR_ANY  = 0
Client.INVALID_SOCKET     = -1

Client.WSAData   WSADATA

Client.hTCPSock  dd ?
Client.hUDPSock  dd ?

Client.hTCPQueueClient dd ?
Client.hTCPQueueServer dd ?

Client.sockAddrUDP       sockaddr_in
Client.sockAddrTCP       sockaddr_in

Client.sockAddrTCPQueueClient  sockaddr_in
Client.sockAddrTCPQueueServer  sockaddr_in

Client.maxConn  dd 5
