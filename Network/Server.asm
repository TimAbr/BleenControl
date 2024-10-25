
proc Server.Init uses edx ecx ebx

  stdcall ws_soket_init 
  
  stdcall ws_new_socket, WS_TCP
  
  mov     dword[Server.hTCPSock], eax  
  stdcall ws_new_connection_structure, 0, [Server.YourPort]
  mov     dword[Server.sockAddrTCP], eax  
  
  mov     [addr_size], 16
  
  invoke bind, [Server.hTCPSock], [Server.sockAddrTCP], [addr_size]
  invoke listen, dword[Server.hTCPSock], 10
  
  invoke accept, dword[Server.hTCPSock], 0, addr_size 
  mov     dword[Client.hTCPSock], eax
  ret
endp

proc Server.Destroy
     stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
     invoke closesocket, [Server.hTCPSock]
.Finish:
     ret
endp