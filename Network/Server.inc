Server.YourIP    db '127.000.000.001', 0
;Server.YourIP    db '192.168.133.97', 0
Server.YourPort  dd 1111
Server.YourP2PPort  dd 1111
Server.FakeIP   db  '0.0.0.0', 0

Server.hTCPSock  dd ?
Server.hUDPSock  dd ?

Server.sockAddrUDP       sockaddr_in
Server.sockAddrTCP       sockaddr_in

addr_size   dd ?