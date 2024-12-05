proc Client.Init uses edx ecx ebx, serverIp, serverPort
  locals
      pos_add   dd   1.5
  endl

  stdcall ws_soket_init 
  
  stdcall ws_new_socket, WS_TCP
  
  mov     dword[Client.hTCPSock], eax  
  stdcall ws_new_connection_structure, [serverIp], [serverPort]
  mov     dword[Client.sockAddrTCP], eax  
  
  stdcall ws_tcp_connect, [Client.hTCPSock], [Client.sockAddrTCP]
  
  ret
endp

proc Client.Destroy
     stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.closeConnection, 4
     invoke closesocket, [Client.hTCPSock]
.Finish:
     ret
endp