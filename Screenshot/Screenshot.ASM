proc    ShowImage uses eax ebx ecx edx, filename, left, top, right, bottom
        
        invoke WaitForSingleObject, [thread_recieve], 100000
        
        invoke  CreateThread, 0, 0, toScreen, thread_rect_2, 0, 0
        mov     [thread_output], eax
          
        
        mov     [temp], 0
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
        
        mov     [temp1], 0
.repit:        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], [lpBuf], [temp]
        add     [lpBuf], eax
        sub     [temp], eax
        add     [temp1], eax
        
        cmp     [temp], 0
        ja      .repit
        
        mov      eax, [temp1]
        sub     [lpBuf], eax
        mov      [temp], eax
        
        mov     [temp1], 0
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], bi, sizeof.BITMAPINFOHEADER
        
        mov     [temp1], 0
        invoke  GetCursorPos, p  

        
        invoke  GetWindowRect, [hwnd], rs
        mov     eax, [rs.left]
        add     eax, 8
        mov     ebx, [rs.top]
        add     ebx, 31
        sub     [p.x], eax
        sub     [p.y], ebx      
       
        mov     eax, [p.y]
        sub     eax, [top]
        jl      .skipMouse
        
        mov     ebx, [bottom]
        cmp     ebx, eax
        jl      .skipMouse
        
        mov     eax, [p.x]
        sub     eax, [left]
        jl      .skipMouse
        mov     ecx, 1920
        xor     edx, edx
        
        mov     ebx, [right]
        cmp     ebx, eax
        jl      .skipMouse
        
        mul     ecx
       
        
        xor     edx, edx
        div     ebx
        
        mov     [MousePos], eax
        
        mov     eax, [p.y]
        sub     eax, [top]
        xor     edx, edx
        mov     ecx, 1080
        mul     ecx
        mov     ebx, [bottom]
        xor     edx, edx
        div     ebx
        
        mov     [MousePos+4], eax
        
        mov     eax, [MouseDown]
        mov     [temp1], eax
        
.skipMouse:                
        
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], MousePos, 8
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        mov      eax, [close_flag_buf]
        add      eax, [close_flag]
        cmp     eax, 0
        je      .skip
        
        stdcall Client.Destroy
        
        mov     [curScreen], start_screen
        mov     [close_flag], 0
        mov     [close_flag_buf], 0
        jmp      .finish
.skip:          
        
        mov     eax, [bottom]
        mov     [thread_rect_2+12], eax
        mov     eax, [right]
        mov     [thread_rect_2+8], eax
        mov     eax, [top]
        mov     [thread_rect_2+4], eax
        mov     eax, [left]
        mov     [thread_rect_2], eax
        
        invoke  CreateThread, 0, 0, recieve_tcp, [temp], 0, 0
        mov     [thread_recieve], eax
.finish:                
        ret
endp



proc recieve_tcp uses eax ebx ecx edx, size

        cmp     [minimized], 0
        jnz     .skipDraw
        
        invoke WaitForSingleObject, [thread_output], 100000

        invoke  Decompress, [Decompressor], [lpBuf], [size], [lpbitmap], [dwBmpSize], temp_recieve
       
        invoke  SetDIBits, [hdcMemDC], [hbmScreen], 0, 1080, [lpbitmap], bi ,0
                

.skipDraw:        

    ret

endp






proc toScreen uses eax ebx ecx edx, rect

    cominvk DDSBack, GetDC, hdc
    invoke  SetStretchBltMode, [hdc], HALFTONE
    mov     eax, [rect]
    invoke  StretchBlt, [hdc], [eax], [eax+4], [eax+8], [eax+12], [hdcMemDC], 0, 0, 1920, 1080, SRCCOPY
    cominvk DDSBack, ReleaseDC, [hdc]
    ret

endp



proc send_tcp uses eax ebx ecx edx, size

        mov     eax, [size]
        mov     [temp1], eax
        
        invoke  GetTickCount
        mov     [ticks_send], eax
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        mov     [temp1], 0
        
        push    [lpBuf]
.repit: 
       
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], [lpBuf], [size]

        
        add     [lpBuf], eax
        sub     [size], eax
        add     [temp1], eax
        
        cmp     dword[size], 0
        ja      .repit
        
        mov      eax, [temp1]
        sub      [lpBuf], eax
        mov      [size], eax
        
        pop       [lpBuf]
        

        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], bi, sizeof.BITMAPINFOHEADER
        
        invoke  wvsprintf, buf_send, buf_format, ticks_send    
        
        
        invoke WaitForSingleObject, [thread_control], 100000                        
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], MousePos, 8
        
        invoke  wvsprintf, buf_x_pos, buf_format, MousePos
        invoke  wvsprintf, buf_y_pos, buf_format, MousePos+4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
        
        invoke  CreateThread, 0, 0, control, 0, 0, 0
        mov     [thread_control], eax
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
        invoke  GetTickCount
        sub     [ticks_send], eax
        neg     [ticks_send]
        
        mov      eax, [close_flag_buf]
        add      eax, [close_flag]
        cmp     eax, 0
        je      .finish
        
        invoke  WaitForMultipleObjects, 5, thread_output, TRUE, 10000
        
        stdcall Server.Destroy
        
        mov     [curScreen], start_screen
        mov     [close_flag], 0
        mov     [close_flag_buf], 0
        
.finish:
    ret

endp   



proc control uses eax ebx ecx edx
        push    [MousePos]
        push    [MousePos+4]
        
        mov     eax, 65535
        xor     edx, edx
        mul     [MousePos]
        xor     edx, edx
        mov     ecx, 1920
        div     ecx
        mov     [MousePos], eax
        
        mov     eax, 65535
        xor     edx, edx
        mul     [MousePos+4]
        xor     edx, edx
        mov     ecx, 1080
        div     ecx
        mov     [MousePos+4], eax
        
        mov     eax, [temp]
        cmp     eax, [MouseDown]
        je      .skipMouseState
        mov     [MouseDown], eax
        cmp     [MouseDown], 0
        je      .up
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTDOWN, dword[MousePos], dword[MousePos+4],0,0
        jmp     .skipMouseState
.up:    
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTUP, dword[MousePos], dword[MousePos+4],0,0   
.skipMouseState:      
        ;invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_MOVE, dword[MousePos], dword[MousePos+4],0,0
        pop     [MousePos+4]
        pop     [MousePos]
   ret
endp


proc    GetScreenshot uses eax ebx edx, hwnd, left, top, right, bottom

        mov     ebx, esp
        
        invoke  GetTickCount
        mov     [ticks_output], eax
         
        
        invoke  BitBlt, [hdcMemDC], 0, 0, 1920, 1080, [hdcScreen], 0, 0, SRCCOPY


        invoke  SetThreadDpiAwarenessContext, -2
        invoke  GetCursorPos, p
        invoke  DrawIcon, [hdcMemDC], [p.x], [p.y], [wc.hCursor]
        invoke  SetThreadDpiAwarenessContext, -1


        invoke  GetTickCount
        sub     [ticks_output], eax
        neg     [ticks_output]
        
        invoke  wvsprintf, buf_output, buf_format, ticks_output


        
        invoke  GetTickCount
        mov     [ticks_compress], eax
        


        invoke  GetDIBits, [hdcMemDC], [hbmScreen], 0, [bmpScreen.bmHeight], [lpbitmap], bi, 0
        
        
        cmp     [minimized], 0
        jnz     .skipDraw
        
        mov     eax, [bottom]
        mov     [thread_rect_1+12], eax
        mov     eax, [right]
        mov     [thread_rect_1+8], eax
        mov     eax, [top]
        mov     [thread_rect_1+4], eax
        mov     eax, [left]
        mov     [thread_rect_1], eax
        invoke  CreateThread, 0, 0, toScreen, thread_rect_1, 0, 0
        mov     [thread_output], eax
        
.skipDraw:
        
        invoke WaitForSingleObject, [thread_send], 100000
        
        push    0    ;CompressedDataSize   -4

        sub     ebx, 4
        invoke  Compress, [Compressor], [lpbitmap], [bmfHeader.bfSize], [lpBuf], [dwBmpSize], ebx
        add     ebx, 4
        
        invoke  GetTickCount
        sub     [ticks_compress], eax
        neg     [ticks_compress]
        
        push    ebx
        invoke  wvsprintf, buf_compress, buf_format, ticks_compress
        pop     ebx

        invoke  CreateThread, 0, 0, send_tcp, [ebx-4], 0, 0
        mov     [thread_send], eax


        mov     esp, ebx
        ret

endp