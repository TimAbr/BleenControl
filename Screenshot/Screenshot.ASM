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
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4

        
        invoke  GetTickCount
        mov     [ticks_send], eax
        
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


        invoke  GetTickCount
        sub     [ticks_send], eax
        neg     [ticks_send]
        
        invoke  wvsprintf, buf_send, buf_format, ticks_send
        
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
        mov      eax, [close_flag_buf]
        add      eax, [close_flag]
        cmp     eax, 0
        je      .finish
        
        stdcall Server.Destroy
        
        mov     [curScreen], start_screen
        mov     [close_flag], 0
        mov     [close_flag_buf], 0
        
.finish:
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