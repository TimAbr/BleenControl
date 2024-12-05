proc    ShowImage uses eax ebx ecx edx, filename, left, top, right, bottom
                   
        
        invoke WaitForSingleObject, [thread_recieve], 100000
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_res, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], cur_res, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_flag, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], change_flag, 4
        
        
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
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], window_active, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], MousePos, 8
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        mov      eax, [close_flag_buf]
        add      eax, [close_flag]
        cmp     eax, 0
        je      .skip
        
        invoke  WaitForMultipleObjects, 5, thread_output, TRUE, 10000
        
        stdcall Client.Destroy
        
        mov     [curScreen], start_screen
        mov     [close_flag], 0
        mov     [close_flag_buf], 0
        jmp      .finish
.skip:          
                
        invoke WaitForSingleObject, [thread_output], 100000
        
        
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
        
        
        cmp    [change_flag], 0
        je      .cur0        
.cur1:  
        invoke WaitForSingleObject, [thread_recieve], 100000
        stdcall  recreateBMP
        jmp     .setresfinish


.cur0:    
        cmp    [temp_flag], 0
        je      .flag00
.flag01:
        invoke WaitForSingleObject, [thread_recieve], 100000
        mov      eax, [temp_res]
        mov     [cur_res], eax
        stdcall  recreateBMP
        jmp     .setresfinish
.flag00: 
        jmp     .setresfinish

.setresfinish:

        mov     [change_flag], 0
        
        
        
        
.finish:                
        ret
endp



proc recieve_tcp uses eax ebx ecx edx, size

        cmp     [minimized], 0
        jnz     .skipDraw

        invoke  Decompress, [Decompressor], [lpBuf], [size], [lpbitmap], [dwBmpSize], temp_recieve
       
        invoke  SetDIBits, [hdcMemDC], [hbmScreen], 0, 1080, [lpbitmap], bi ,0
                

.skipDraw:        

    ret

endp






proc toScreen uses eax ebx ecx edx, rect

    cominvk DDSBack, GetDC, hdc
    invoke  SetStretchBltMode, [hdc], HALFTONE
    mov     eax, [rect]
    invoke  StretchBlt, [hdc], [eax], [eax+4], [eax+8], [eax+12], [hdcMemDC], 0, 0, [image_width], [image_height], SRCCOPY
    cominvk DDSBack, ReleaseDC, [hdc]
    ret

endp



proc send_tcp uses eax ebx ecx edx, size

        mov     eax, [size]
        mov     [temp1], eax
        
        invoke  GetTickCount
        mov     [ticks_send], eax
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], cur_res, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_res, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], change_flag, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_flag, 4
        
        
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
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], window_active, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], MousePos, 8
        
        invoke  wvsprintf, buf_x_pos, buf_format, MousePos
        invoke  wvsprintf, buf_y_pos, buf_format, MousePos+4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
        
        cmp     [window_active], 0
        je      .skipControl
        invoke  CreateThread, 0, 0, control, 0, 0, 0
        mov     [thread_control], eax
.skipControl:        
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

        invoke WaitForSingleObject, [thread_output], 100000 
        
        cmp    [change_flag], 0
        je      .cur0


.cur1:  
        cmp    [temp_flag], 0
        je      .flag10
.flag11:
        mov      eax, [temp_res]
        mov     [cur_res], eax
        stdcall  recreateBMP
        jmp     .setresfinish     
.flag10:
        jmp     .setresfinish


.cur0:    
        cmp    [temp_flag], 0
        je      .flag00
.flag01:
        mov      eax, [temp_res]
        mov     [cur_res], eax
        stdcall  recreateBMP
        jmp     .setresfinish
.flag00: 
        jmp     .setresfinish

.setresfinish:
        mov     [change_flag], 0
        
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
        
        ;invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_MOVE, dword[MousePos], dword[MousePos+4],0,0
        
        mov     eax, [temp]
        cmp     eax, [MouseDown]
        je      .skipMouseState
        mov     [MouseDown], eax
        cmp     [MouseDown], 0
        je      .up
        ;invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTDOWN, dword[MousePos], dword[MousePos+4],0,0
        jmp     .skipMouseState
.up:    
        ;invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTUP, dword[MousePos], dword[MousePos+4],0,0   
.skipMouseState:      
        pop     [MousePos+4]
        pop     [MousePos]
   ret
endp


proc    GetScreenshot uses eax ebx edx, hwnd, left, top, right, bottom

        mov     ebx, esp
        
        invoke  GetTickCount
        mov     [ticks_output], eax
        
        cmp     [sWidth], 1920
        jle     .setHeight
        shr     [sWidth], 2
        
.setHeight:  
        mov     eax, [sWidth]
        shr     eax, 4
        mov     ecx, 9
        xor     edx, edx
        mul     ecx
        mov     [sHeight], eax  
        
                         
   
        invoke  StretchBlt, [hdcMemDC], 0, 0, [image_width], [image_height], [hdcScreen], 0, 0, [sWidth], [sHeight], SRCCOPY
        
        shl     [sWidth], 2
        ;invoke  BitBlt, [hdcMemDC], 0, 0, [image_width], [image_height], [hdcScreen], 0, 0, SRCCOPY


        shr     [sWidth], 2
        
        xor     edx, edx
        mov     eax, 32
        mul     [image_width]
        xor     edx, edx
        div     [sWidth]
        mov     [cursor_size], eax
         
        invoke  SetThreadDpiAwarenessContext, -2
        invoke  GetCursorPos, p
        
        xor     edx, edx
        mov     eax, [p.x]
        mul     [image_width]
        xor     edx, edx
        div     [sWidth]
        mov     [p.x], eax
        
        xor     edx, edx
        mov     eax, [p.y]
        mul     [image_width]
        xor     edx, edx
        div     [sWidth]
        mov     [p.y], eax
        
        invoke  DrawIconEx, [hdcMemDC], [p.x], [p.y], [wc.hCursor], [cursor_size], [cursor_size], 0, 0, DI_NORMAL
        invoke  SetThreadDpiAwarenessContext, -1

        shl     [sWidth], 2

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




proc recreateBMP uses eax ebx ecx edx


        mov     [res360Btn.color], menu_color
        mov     [res480Btn.color], menu_color
        mov     [res720Btn.color], menu_color
        mov     [res1080Btn.color], menu_color
        
        cmp     [cur_res], res1080
        jg      .res720
        mov     [image_width], 1920
        mov     [image_height], 1080
        mov     [res1080Btn.color], main_color
        jmp     .skipRes
        
.res720:
        cmp     [cur_res], res720
        jg      .res480
        mov     [image_width], 1280
        mov     [image_height], 720
        mov     [res720Btn.color], main_color
        jmp     .skipRes
.res480:
        cmp     [cur_res], res480
        jg      .res360
        mov     [image_width], 854
        mov     [image_height], 480
        mov     [res480Btn.color], main_color
        jmp     .skipRes
.res360:
        mov     [image_width], 640
        mov     [image_height], 360
        mov     [res360Btn.color], main_color

.skipRes:

        invoke  DeleteObject, [hbmScreen]

        invoke  CreateCompatibleBitmap, [hdcScreen], [image_width], [image_height]
        mov     [hbmScreen],eax 
        
        invoke  SelectObject, [hdcMemDC], eax
        
        invoke  GetObject, [hbmScreen], sizeof.BITMAP, bmpScreen


        mov     [bi.biSize], sizeof.BITMAPINFOHEADER
        mov     eax, [bmpScreen.bmWidth]
        mov     [bi.biWidth], eax
        mov     eax, [bmpScreen.bmHeight]
        mov     [bi.biHeight], eax
        mov     [bi.biPlanes], 1
        mov     [bi.biBitCount], 32
        mov     [bi.biCompression], BI_RGB
        mov     [bi.biSizeImage], 0
        mov     [bi.biXPelsPerMeter], 0
        mov     [bi.biYPelsPerMeter], 0
        mov     [bi.biClrUsed], 0
        mov     [bi.biClrImportant], 0

        mov     eax, [bmpScreen.bmWidth]
        shl     eax, 5
        add     eax, 31
        shr     eax, 3
        mul     [bmpScreen.bmHeight]
        mov     [dwBmpSize], eax 
                
        
        mov     eax, sizeof.BITMAPFILEHEADER
        add     eax, sizeof.BITMAPINFOHEADER
        add     [dwBmpSize], eax
        mov     [bmfHeader.bfOffBits], eax
        mov     eax, [dwBmpSize]
        mov     [bmfHeader.bfSize], eax
        mov     [bmfHeader.bfType], 0x4D42
    ret

endp
