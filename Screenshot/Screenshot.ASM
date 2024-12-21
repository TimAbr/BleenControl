proc    ShowImage uses eax ebx ecx edx, filename, left, top, right, bottom
        
        invoke WaitForSingleObject, [thread_recieve], 100000
        invoke WaitForSingleObject, [thread_output], 100000 
        
        cmp     [minimized], 0
        jne     .is_minimized  
        
        invoke  CreateThread, 0, 0, toScreen, thread_rect_2, 0, 0
        mov     [thread_output], eax
.is_minimized: 
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], SmoothMouse, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], MouseControl, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], KeyboardControl, 4           
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_res, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], cur_res, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_flag, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], change_flag, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], min_x, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], min_y, 4 
             
                  
        
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
        
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], bi_res, sizeof.BITMAPINFOHEADER
        
;/////////////////////////


        push    [lpBuf]
        mov     eax, [dwBmpSize]
        shr     eax, 1
        add     [lpBuf], eax
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], min_x_proc, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], min_y_proc, 4 
             
                  
        
        mov     [temp_compress_2], 0
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_compress_2, 4
        
        
        mov     [temp1], 0
.repit2:        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], [lpBuf], [temp_compress_2]
        add     [lpBuf], eax
        sub     [temp_compress_2], eax
        add     [temp1], eax
        
        cmp     [temp_compress_2], 0
        ja      .repit2
        
        mov      eax, [temp1]
        sub     [lpBuf], eax
        mov      [temp_compress_2], eax
        
        mov     [temp1], 0
        
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], bi_res_proc, sizeof.BITMAPINFOHEADER
        pop     [lpBuf]

;/////////////////////        
        
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
        
        mov     eax, [MouseTotal]
        mov     [temp1], eax
        
.skipMouse:                
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], window_active, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], MousePos, 8
        
        cmp    [window_active], 0
        je      .clearmouselist
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        cmp    [temp1], 0
        je      .clearmouselist
         
        mov   ebx, [MouseHead.NextP]
        mov   ecx, [temp1]
.mouseloop:
        push   ecx
        mov     eax, [ebx]
        mov     [temp1], eax
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        mov     eax, [ebx+4]
        mov     [temp1], eax
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        mov   eax, [ebx+8]
        mov   ebx, eax  
        pop    ecx      
        loop  .mouseloop
        
.clearmouselist:
        mov   ecx, [MouseTotal]
        test  ecx, ecx
        jz    .SkipMouseList
.clearloop:  
        push  ecx      
        mov   ebx, [MouseHead.NextP]
        push  dword[ebx+8]
        push  dword[ebx+12]
        invoke GlobalUnlock, [MouseHead.NextH]
        invoke GlobalFree, [MouseHead.NextH]
        pop   eax
        mov   [MouseHead.NextH], eax
        pop   eax
        mov   [MouseHead.NextP], eax
        pop   ecx
        loop  .clearloop
        
        mov   [MouseTotal], 0
        mov   [MouseCur], MouseHead
.SkipMouseList:         

        cmp    [window_active], 0
        je      .clearkeyboardlist
        mov     eax, [KeyboardTotal]
        mov     [temp1], eax
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        cmp    [temp1], 0
        je      .clearkeyboardlist
         
        mov   ebx, [KeyboardHead.NextP]
        mov   ecx, [temp1]
.keyboardloop:
        push   ecx
        mov     eax, [ebx]
        mov     [temp1], eax
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        mov     eax, [ebx+4]
        mov     [temp1], eax
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        mov   eax, [ebx+8]
        mov   ebx, eax  
        pop    ecx      
        loop  .keyboardloop
        
.clearkeyboardlist:
        mov   ecx, [KeyboardTotal]
        test  ecx, ecx
        jz    .SkipKeyboardList
.clearKeyboardloop:  
        push  ecx      
        mov   ebx, [KeyboardHead.NextP]
        push  dword[ebx+8]
        push  dword[ebx+12]
        invoke GlobalUnlock, [KeyboardHead.NextH]
        invoke GlobalFree, [KeyboardHead.NextH]
        pop   eax
        mov   [KeyboardHead.NextH], eax
        pop   eax
        mov   [KeyboardHead.NextP], eax
        pop   ecx
        loop  .clearKeyboardloop
        
        mov   [KeyboardTotal], 0
        mov   [KeyboardCur], KeyboardHead
.SkipKeyboardList:   




     
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
        
        ;invoke WaitForSingleObject, [thread_decompress], 100000
        invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        
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
                                
        invoke  CreateCompatibleBitmap, [hdcMemDC], [bi_res.biWidth], [bi_res.biHeight]
        mov     [hbmScreen_res],eax 
        
        invoke  SelectObject, [hdcMemDC_res], eax   
        
        ;invoke  Decompress, [Decompressor], [lpBuf], [size], [lpbitmap], [dwBmpSize], temp_recieve
        invoke  Decompress, [Decompressor], [lpBuf], [size], [lpbitmap_res], [dwBmpSize], temp_recieve
        
        mov     [bi_res.biBitCount], 32
        mov     [bi_res.biCompression], BI_RGB  
        
        invoke  SetDIBits, [hdcMemDC_res], [hbmScreen_res], 0, [bi_res.biHeight], [lpbitmap_res], bi_res ,0
                
        invoke  BitBlt, [hdcMemDC], [min_x], [min_y], [bi_res.biWidth], [bi_res.biHeight], [hdcMemDC_res], 0, 0, SRCCOPY
        
        invoke  DeleteObject, [hbmScreen_res]
        
        
        
        
        
        invoke  CreateCompatibleBitmap, [hdcMemDC], [bi_res_proc.biWidth], [bi_res_proc.biHeight]
        mov     [hbmScreen_res_proc],eax 
        
        invoke  SelectObject, [hdcMemDC_res_proc], eax
        
        ;invoke  Decompress, [Decompressor], [lpBuf], [size], [lpbitmap], [dwBmpSize], temp_recieve
        push    [lpBuf]
        push    [lpbitmap_res]
        
        mov     eax, [dwBmpSize]
        shr     eax, 1
        add     [lpBuf], eax
        add     [lpbitmap_res], eax
        
        mov     [temp_recieve], 0
        invoke  Decompress, [Decompressor], [lpBuf], [temp_compress_2], [lpbitmap_res], eax, temp_recieve
        
        mov     [bi_res_proc.biBitCount], 32
        mov     [bi_res_proc.biCompression], BI_RGB
        
        invoke  SetDIBits, [hdcMemDC_res_proc], [hbmScreen_res_proc], 0, [bi_res_proc.biHeight], [lpbitmap_res], bi_res_proc ,0
        
        pop     [lpbitmap_res]
        pop     [lpBuf]
                
        invoke  BitBlt, [hdcMemDC], [min_x_proc], [min_y_proc], [bi_res_proc.biWidth], [bi_res_proc.biHeight], [hdcMemDC_res_proc], 0, 0, SRCCOPY
        
        invoke  DeleteObject, [hbmScreen_res_proc]
        
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
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], SmoothMouse, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], MouseControl, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], KeyboardControl, 4
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], cur_res, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_res, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], change_flag, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp_flag, 4
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], min_x, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], min_y, 4
        
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp1, 4
        
        mov     [temp1], 0
        
        push    [lpBuf]
        ;mov     eax, [lpTempBuf]
        ;mov     [lpBuf], eax
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
        

        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], bi_res, sizeof.BITMAPINFOHEADER
        
        
        
        ;////////////////////////
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], min_x_proc, 4
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], min_y_proc, 4
        
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], temp_compress_2, 4
        
        mov     [temp1], 0
        
        push    [lpBuf]
        mov     eax, [dwBmpSize]
        shr     eax, 1
        add     [lpBuf], eax
        
        ;mov     eax, [lpTempBuf]
        ;mov     [lpBuf], eax
.repit2: 
       
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], [lpBuf], [temp_compress_2]

        
        add     [lpBuf], eax
        sub     [temp_compress_2], eax
        add     [temp1], eax
        
        cmp     dword[temp_compress_2], 0
        ja      .repit2
        
        mov      eax, [temp1]
        sub      [lpBuf], eax
        mov      [temp_compress_2], eax
        
        pop       [lpBuf]
        

        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], bi_res_proc, sizeof.BITMAPINFOHEADER
        
        
        ;//////////////////////////
        
        invoke  wvsprintf, buf_send, buf_format, ticks_send    
        
        
        ;invoke WaitForSingleObject, [thread_control], 100000                        
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], window_active, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], MousePos, 8
        
        invoke  wvsprintf, buf_x_pos, buf_format, MousePos
        invoke  wvsprintf, buf_y_pos, buf_format, MousePos+4
        
        
        cmp     [window_active], 0
        je      .skipControl
        stdcall control

.skipControl: 
        
       
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
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
        mov     eax, [change_flag]
        add     [temp_flag], eax
        mov     [change_flag], 0
        
        invoke  GetTickCount
        sub     [ticks_send], eax
        neg     [ticks_send]
        
    ret

endp   


proc movemouse uses eax ebx ecx edx
    invoke  SetThreadDpiAwarenessContext, -2
    invoke  GetCursorPos, p
    invoke  SetThreadDpiAwarenessContext, -1
    
    stdcall  drawLine_mouse, [p.x], [p.y], dword[MousePos], dword[MousePos+4] 
    
    ret
endp





proc control uses eax ebx ecx edx


        push    [MousePos]
        push    [MousePos+4]
        
        mov     eax, [MousePos]
        mov     [MousePos_temp], eax
        mov     eax, [MousePos+4]
        mov     [MousePos_temp+4], eax
        
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
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp1, 4
        
        invoke  wvsprintf, buf_clicks, buf_format, temp1
        
        cmp     [MouseControl], 0
        je      .SkipMove
        
        cmp     [SmoothMouse], 0
        jne     .smooth
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_MOVE, dword[MousePos], dword[MousePos+4],0,0
        jmp     .SkipMove
.smooth:        
        stdcall  drawLine_mouse,[MousePos_last],[MousePos_last+4],[MousePos_temp],[MousePos_temp+4]
.SkipMove:
        push    eax
        push    ebx
        mov     eax, [MousePos_temp]
        mov     ebx, [MousePos_temp+4]
        mov     [MousePos_last],eax 
        mov     [MousePos_last+4],ebx
        pop     ebx
        pop     eax 

        mov     ecx, [temp1]
        test    ecx, ecx
        jz      skipMouseCycle
mouseloop:
        push    ecx        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
        cmp     [temp], 1
        jne     RightBtn
LeftBtn:      
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4  
        mov     eax, [temp]
        ;cmp     eax, [MouseDown]
        ;je      .skipMouseState
        
        cmp     [MouseControl], 0
        je      skipMouseState
        
        mov     [MouseDown], eax
        test    eax, eax
        je      .up
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTDOWN, dword[MousePos], dword[MousePos+4],0,0
        jmp     skipMouseState
.up:    
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_LEFTUP, dword[MousePos], dword[MousePos+4],0,0  
        jmp     skipMouseState 
        
RightBtn: 
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4  
        mov     eax, [temp]
        ;cmp     eax, [MouseDown]
        ;je      .skipMouseState
        
        cmp     [MouseControl], 0
        je      skipMouseState
        
        mov     [MouseDown], eax
        test    eax, eax
        je      .up
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_RIGHTDOWN, dword[MousePos], dword[MousePos+4],0,0
        jmp     skipMouseState
.up:    
        invoke   mouse_event, MOUSEEVENTF_ABSOLUTE+MOUSEEVENTF_RIGHTUP, dword[MousePos], dword[MousePos+4],0,0
               
         
skipMouseState: 
        pop     ecx
        dec     ecx
        jnz     mouseloop
skipMouseCycle:
             
        pop     [MousePos+4]
        pop     [MousePos]
        
        
        
        
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp1, 4
        

        mov     ecx, [temp1]
        test    ecx, ecx
        jz      skipKeyboardCycle
keyboardloop:
        push    ecx        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp1, 4
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4  
        mov     eax, [temp]
        
        cmp     [KeyboardControl], 0
        je      skipKeyboardState
        
        test    eax, eax
        je      .up
        invoke   keybd_event, dword[temp1], 0, 0, 0
        jmp     skipKeyboardState
.up:    
        invoke   keybd_event, dword[temp1], 0, 2, 0
               
         
skipKeyboardState: 
        pop     ecx
        dec     ecx
        jnz     keyboardloop
skipKeyboardCycle:
        
control.finish:
   ret
endp



proc  compress_2 uses eax ebx ecx edx
        push    esi
        push    edi
        
        cmp     [change_flag], 0
        jne     .SkipDirtyRect
        
        cmp     [temp_flag], 0
        jne     .SkipDirtyRect
        
        ;find the changed part
        
        mov     [max_x_proc], 0
        mov     [max_y_proc], 0
        mov     eax,  [bi.biWidth]
        mov     [min_x_proc], eax
        mov     eax, [bi.biHeight]
        mov     [min_y_proc], eax 
        mov     edi, dword[lpbitmap_temp]
        mov     ecx, [bi.biWidth]
        shl     ecx, 1
        add     edi, ecx
        mov     esi, dword[lpbitmap]
        add     esi, ecx
        mov     ecx, [bi.biHeight]
.outer_loop:
        mov     edx, [bi.biWidth]
        shr     edx, 1
        
.inner_loop:        
        mov     eax, dword[esi]
        xor     eax, dword[edi]
        jz      .next
        
        mov     eax, [bi.biWidth]
        sub     eax, edx 
        cmp     eax, [min_x_proc]
        ja      .skipminx
        mov     [min_x_proc], eax
.skipminx:           
        cmp     eax, [max_x_proc]
        jb      .skipmaxx
        mov     [max_x_proc], eax
.skipmaxx:

        ;mov     eax, [bi.biHeight]
        ;sub     eax, ecx 
        mov     eax, ecx
        dec     eax  
        cmp     eax, [min_y_proc]
        ja      .skipminy
        mov     [min_y_proc], eax
.skipminy:           
        cmp     eax, [max_y_proc]
        jb      .skipmaxy
        mov     [max_y_proc], eax
.skipmaxy:
        
               
.next:
        add     edi, 4
        add     esi, 4
        dec     edx
        jnz     .inner_loop          
        
        add     edi, [bi.biWidth]
        add     edi, [bi.biWidth]
        ;sub     edi, 4 
        add     esi, [bi.biWidth]
        add     esi, [bi.biWidth]
        ;sub     esi, 4 
        dec     ecx
        jnz     .outer_loop
        
        mov     eax, [min_x_proc]
        cmp     [max_x_proc], eax
        jge      .EndRect
        
        dec     eax
        dec     eax
        mov     [min_x], eax
        mov     [min_y], eax
        inc     eax
        mov     [max_x], eax
        mov     [max_y], eax
        
        jmp     .EndRect
        
.SkipDirtyRect:
        mov     [min_x_proc], 0
        mov     [min_y_proc], 0
        mov     eax, [bi.biWidth]
        shr     eax,1
        mov     [min_x_proc], eax
        shl     eax,1
        dec     eax
        mov     [max_x_proc], eax
        mov     eax, [bi.biHeight]
        shr     eax,1
        mov     [min_y_proc], eax
        shl     eax,1
        dec     eax
        mov     [max_y_proc], eax
.EndRect:   
        
        pop    edi
        pop    esi
        
        
        mov     eax, [max_x_proc]
        sub     eax, [min_x_proc]
        inc     eax
        
        mov     edx, [max_y_proc]
        sub     edx, [min_y_proc]
        inc     edx
        
        push    eax
        push    edx
        
        invoke  CreateCompatibleBitmap, [hdcMemDC], eax, edx
        mov     [hbmScreen_res_proc], eax 
        
        invoke  SelectObject, [hdcMemDC_res_proc], eax
        
        pop     edx
        pop     eax
        
        mov     [bi_res_proc.biWidth], eax
        mov     [bi_res_proc.biHeight], edx
        
        invoke  BitBlt, [hdcMemDC_res_proc], 0, 0, [bi_res_proc.biWidth], [bi_res_proc.biHeight], [hdcMemDC], [min_x_proc], [min_y_proc], SRCCOPY
        
        mov     [bi_res_proc.biBitCount], 32
        mov     [bi_res_proc.biCompression], BI_RGB
        
        mov     ebx,[dwBmpSize]
        shr     ebx, 1
        add     ebx, [lpbitmap_res]
        invoke  GetDIBits, [hdcMemDC_res_proc], [hbmScreen_res_proc], 0, [bi_res_proc.biHeight], ebx, bi_res_proc, 0
        
        mov     eax, [bi_res_proc.biWidth]
        shl     eax, 2
        mul     [bi_res_proc.biHeight]
        mov     [bi_res_proc.biSizeImage], eax  
        
        mov     ebx,[dwBmpSize]
        shr     ebx, 1
        add     ebx, [lpbitmap_res]      
        
        mov     edx,[dwBmpSize]
        shr     edx, 1
        add     edx, [lpBuf]  
        
        mov     ecx, [dwBmpSize]
        shr     ecx, 1    
        
        invoke  Compress, [Compressor1], ebx, [bi_res_proc.biSizeImage], edx, ecx, temp_compress_2

    ret
endp



proc    GetScreenshot uses eax ebx edx , hwnd, left, top, right, bottom

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
        
        
        invoke WaitForSingleObject, [thread_send], 100000
        
        mov     eax, [lpbitmap]
        xchg    eax, [lpbitmap_temp]
        mov     [lpbitmap], eax

        invoke  GetDIBits, [hdcMemDC], [hbmScreen], 0, [bmpScreen.bmHeight], [lpbitmap], bi, 0
        
        
        push    esi
        push    edi
        
        
        
        cmp     [change_flag], 0
        jne     .SkipDirtyRect
        
        cmp     [temp_flag], 0
        jne     .SkipDirtyRect
        
        ;find the changed part
        push    [lpbitmap]
        push    [lpbitmap_temp]
        
        mov     [max_x], 0
        mov     [max_y], 0
        mov     eax,  [bi.biWidth]
        mov     [min_x], eax
        mov     eax, [bi.biHeight]
        mov     [min_y], eax 
        
        
        invoke  CreateThread, 0, 0, compress_2, 0, 0, 0
        mov     [thread_compress], eax 
        
        mov     edi, dword[lpbitmap_temp]
        mov     esi, dword[lpbitmap]
        
        mov     ecx, [bi.biHeight]
.outer_loop:
        mov     edx, [bi.biWidth]
        
.inner_loop:        
        mov     eax, dword[esi]
        xor     eax, dword[edi]
        jz      .next
        
        mov     eax, [bi.biWidth]
        sub     eax, edx 
        cmp     eax, [min_x]
        ja      .skipminx
        mov     [min_x], eax
.skipminx:           
        cmp     eax, [max_x]
        jb      .skipmaxx
        mov     [max_x], eax
.skipmaxx:

        ;mov     eax, [bi.biHeight]
        ;sub     eax, ecx 
        mov     eax, ecx
        dec     eax  
        cmp     eax, [min_y]
        ja      .skipminy
        mov     [min_y], eax
.skipminy:           
        cmp     eax, [max_y]
        jb      .skipmaxy
        mov     [max_y], eax
.skipmaxy:
        
               
.next:
        add     edi, 4
        add     esi, 4
        dec     edx
        mov     eax, [bi.biWidth]
        shr     eax, 1
        cmp     edx, eax
        jae     .inner_loop          
        

        add     edi, [bi.biWidth]
        add     edi, [bi.biWidth]
        sub     edi, 4 
        add     esi, [bi.biWidth]
        add     esi, [bi.biWidth]
        sub     esi, 4 
        dec     ecx
        jnz     .outer_loop
        
        
        pop     [lpbitmap_temp]
        pop     [lpbitmap]
        
        
        mov     eax, [min_x]
        cmp     [max_x], eax
        jge      .EndRect
        
        mov     [min_x], 0
        mov     [min_y], 0
        mov     [max_x], 1
        mov     [max_y], 1
        jmp     .EndRect
        
.SkipDirtyRect:
        mov     [min_x], 0
        mov     [min_y], 0
        mov     eax, [bi.biWidth]
        dec     eax
        mov     [max_x], eax
        mov     eax, [bi.biHeight]
        dec     eax
        mov     [max_y], eax
.EndRect:   
        ;dec     [min_y]
        ;dec     [max_y]     
        invoke  wvsprintf, buf_min_x, buf_format, min_x
        invoke  wvsprintf, buf_min_y, buf_format, min_y
        invoke  wvsprintf, buf_max_x, buf_format, max_x
        invoke  wvsprintf, buf_max_y, buf_format, max_y

        invoke WaitForSingleObject, [thread_compress], 100000 
        
        pop    edi
        pop    esi
        
        
        mov     eax, [max_x]
        sub     eax, [min_x]
        inc     eax
        
        mov     edx, [max_y]
        sub     edx, [min_y]
        inc     edx
        
        push    eax
        push    edx
        
        
        invoke  CreateCompatibleBitmap, [hdcMemDC], eax, edx
        mov     [hbmScreen_res],eax 
        
        invoke  SelectObject, [hdcMemDC_res], eax
        
        
        pop     edx
        pop     eax
        
        
        mov     [bi_res.biWidth], eax
        mov     [bi_res.biHeight], edx
        
        invoke  BitBlt, [hdcMemDC_res], 0, 0, [bi_res.biWidth], [bi_res.biHeight], [hdcMemDC], [min_x], [min_y], SRCCOPY
        
        mov     [bi_res.biBitCount], 32
        mov     [bi_res.biCompression], BI_RGB
        
        invoke  GetDIBits, [hdcMemDC_res], [hbmScreen_res], 0, [bi_res.biHeight], [lpbitmap_res], bi_res, 0
        
        mov     eax, [bi_res.biWidth]
        shl     eax, 2
        mul     [bi_res.biHeight]
        mov     [bi_res.biSizeImage], eax
        
        
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

        
        push    0    ;CompressedDataSize   -4

        sub     ebx, 4
        invoke  Compress, [Compressor], [lpbitmap_res], [bi_res.biSizeImage], [lpBuf], [dwBmpSize], ebx
        mov    eax, [temp_compress_2]
        add    [ebx], eax
        invoke  wvsprintf, buf_img_size, buf_format, ebx
        mov    eax, [temp_compress_2]
        sub    [ebx], eax
        add     ebx, 4
        
        mov     [bi_res.biSizeImage], 0
        
        
        
        invoke  GetTickCount
        sub     [ticks_compress], eax
        neg     [ticks_compress]
        
        push    ebx
        invoke  wvsprintf, buf_compress, buf_format, ticks_compress
        pop     ebx

        ;stdcall  send_tcp, [ebx-4]
        invoke  CreateThread, 0, 0, send_tcp, [ebx-4], 0, 0
        mov     [thread_send], eax   
        
        invoke  DeleteObject, [hbmScreen_res]


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
        ;mul     [bi.biBitCount]
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
