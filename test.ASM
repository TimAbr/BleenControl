
; Template for program using standard Win32 headers

format PE GUI 4.0
entry start

include 'win32w.inc'

include 'ddraw.inc'

include 'help.inc'


section '.text' code readable executable

  start:

        and     [DDraw],0
        and     [DDSMain],0
        and     [DDSBack],0


        invoke  GetModuleHandle,0
        mov     [wc.hInstance],eax  ;дескриптор приложения, который вызывает окно

        invoke  LoadIcon,0,IDI_APPLICATION
        mov     [wc.hIcon],eax  ;дескриптор пиктограммы

        invoke  LoadCursor,0,IDC_ARROW
        mov     [wc.hCursor],eax   ;дескриптор курсора

        invoke  RegisterClass,wc   ; регистрация класса окна
                                   ; сообщает ОС вид окна и его функцию
                                   ; не создаёт окно
        test    eax,eax
        jz      startup_error

        invoke  CreateWindowEx, 0,\
                                _class,\ ; имя класса
                                _title,\  ; заголовок окна
                                WS_VISIBLE+WS_OVERLAPPEDWINDOW,\  ;стиль окна
                                128,\  ; х окна
                                128,\  ; у окна
                                780,\  ; ширина окна
                                512,\  ; высота окна
                                NULL,\ ; указатель родительского окна
                                NULL,\ ; дескриптор меню (меню нет - null)
                                [wc.hInstance],\ ; дескриптор приложения
                                NULL   ; данные, которые могут быть переданы при создании окна
                                       ; null - не передаются
        test    eax,eax
        jz      startup_error
        mov     [hwnd], eax
        
        
        ;invoke  CreateWindowEx, 0,\
        ;                        _button_class,\ ; имя класса
        ;                        _button_text,\  ; заголовок окна
        ;                        WS_TABSTOP+WS_VISIBLE+WS_CHILD+BS_CHECKBOX,\  ;стиль окна
        ;                        40,\  ; х окна
        ;                        40,\  ; у окна
        ;                        200,\  ; ширина окна
        ;                        200,\  ; высота окна
        ;                        [hwnd],\ ; указатель родительского окна
        ;                        1,\ ; дескриптор меню (меню нет - null)
        ;                        [wc.hInstance],\ ; дескриптор приложения
        ;                        NULL   ; данные, которые могут быть переданы при создании окна
        ;                               ; null - не передаются
        ;mov   [hCheckBoxDev], eax
        
        ;invoke  CheckDlgButton, [hwnd], 1, BST_CHECKED

        invoke  DirectDrawCreate,NULL,DDraw,NULL  ; создание интерфейса DirectDraw
        test    eax,eax
        jnz     ddraw_error

        cominvk DDraw,SetCooperativeLevel,\             ; степень контроля над видеокартой
                [hwnd],DDSCL_NORMAL
        test    eax,eax
        jnz     ddraw_error

        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],DDSD_CAPS
        mov     [ddsd.ddsCaps.dwCaps], DDSCAPS_PRIMARYSURFACE

        cominvk DDraw,CreateSurface,\
                ddsd,DDSMain,NULL
        test    eax, eax
        jnz     ddraw_error

        
        ;создание клипера для контроля выхода за границы окна
        cominvk DDraw,CreateClipper,\
                0,DDClipper,NULL
        test    eax, eax
        jnz     ddraw_error

        cominvk DDClipper,SetHWnd,\
                0,[hwnd]
        test    eax, eax
        jnz     ddraw_error

        cominvk DDSMain,SetClipper,\
                [DDClipper]
        test    eax, eax
        jnz     ddraw_error
        
        
        ;создание буферной поверхности
        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],DDSD_CAPS+DDSD_HEIGHT+DDSD_WIDTH
        mov     [ddsd.ddsCaps.dwCaps], DDSCAPS_OFFSCREENPLAIN
        mov     eax, [sWidth]
        mov     [ddsd.dwWidth], eax
        mov     eax, [sHeight]
        mov     [ddsd.dwHeight], eax

        cominvk DDraw,CreateSurface,\
                ddsd,DDSBack,NULL
        test    eax, eax
        jnz     ddraw_error
        
        cominvk DDraw,CreateSurface,\
                ddsd,DDSPicture,NULL
        test    eax, eax
        jnz     ddraw_error

        cominvk DDSBack,SetClipper,\
                [DDClipper]
        test    eax, eax
        jnz     ddraw_error

        ;считывание ширины экрана
        invoke  SetThreadDpiAwarenessContext, -2
        invoke  GetSystemMetrics,  SM_CXSCREEN
        mov     [sWidth], eax
        shl     [sWidth], 2
        invoke  SetThreadDpiAwarenessContext, -1

        invoke  GetTickCount
        mov     [last_tick],eax

        ;создание компрессора для сжатия изображений
        invoke  CreateCompressor, 4, NULL, Compressor
        invoke  CreateDecompressor, 4, NULL, Decompressor
         
        stdcall Client.Destroy
        
        invoke  GetDC, NULL
        mov     [hdcScreen], eax 
        
        invoke  CreateCompatibleDC, [hdcScreen]
        mov     [hdcMemDC],eax
        invoke  SetStretchBltMode, eax, HALFTONE
        
        
        invoke  CreateCompatibleDC, [hdcMemDC]
        mov     [hdcMemDC_res],eax
        
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
        shr     eax, 5
        shl     eax, 2
        mul     [bmpScreen.bmHeight]
        mov     [dwBmpSize], eax 
        
        invoke  GlobalAlloc, GHND, [dwBmpSize]
        mov     [hDIB], eax 

        invoke  GlobalLock, eax
        mov     [lpbitmap], eax  
        
        mov     eax, sizeof.BITMAPFILEHEADER
        add     eax, sizeof.BITMAPINFOHEADER
        add     [dwBmpSize], eax
        mov     [bmfHeader.bfOffBits], eax
        mov     eax, [dwBmpSize]
        mov     [bmfHeader.bfSize], eax
        mov     [bmfHeader.bfType], 0x4D42  
                   
        
        invoke  GlobalAlloc, GHND, [dwBmpSize]
        mov     [hBuf], eax

        invoke  GlobalLock, eax
        mov     [lpBuf], eax
        
        
        
        
        mov     [bi_res.biSize], sizeof.BITMAPINFOHEADER
        mov     eax, [bmpScreen.bmWidth]
        mov     [bi_res.biWidth], eax
        mov     eax, [bmpScreen.bmHeight]
        mov     [bi_res.biHeight], eax
        mov     [bi_res.biPlanes], 1
        mov     [bi_res.biBitCount], 32
        mov     [bi_res.biCompression], BI_RGB
        mov     [bi_res.biSizeImage], 0
        mov     [bi_res.biXPelsPerMeter], 0
        mov     [bi_res.biYPelsPerMeter], 0
        mov     [bi_res.biClrUsed], 0
        mov     [bi_res.biClrImportant], 0
        
        invoke  GlobalAlloc, GHND, [dwBmpSize]
        mov     [hDIB_temp], eax 

        invoke  GlobalLock, eax
        mov     [lpbitmap_temp], eax 
        
        
        
        
        
        
        invoke  GlobalAlloc, GHND, [dwBmpSize]
        mov     [hDIB_res], eax 

        invoke  GlobalLock, eax
        mov     [lpbitmap_res], eax 

        
        mov     [cur_res], 1
        stdcall  recreateBMP 
        
        ;stdcall  drawLine_mouse,100,400,500,400
                


  msg_loop:    ; цикл сообщений
               ; необработанные сообщения извлекаются из очереди и передаются ОС
               ; затем ОС вызывает функцию окна
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      end_loop
        jne     wait_msg
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop
        
  wait_msg:
        call    onPaint
        jmp     msg_loop
              

  ddraw_error:

        mov     eax,_ddraw_error
        jmp     error

  startup_error:
        mov     eax,_error
        jmp     error

  error:
        invoke  MessageBox,NULL,eax,NULL,MB_ICONERROR+MB_OK

  end_loop:
  
        mov     [close_flag], 1
        call    onPaint
        
        
        
        
        invoke WaitForSingleObject, [thread_drawInterface], 1000000

        cmp     [DDSBack],0
        je      back_surface_released
        cominvk DDSMain,DeleteAttachedSurface,0,DDSBack

    back_surface_released:
        cmp     [DDSMain],0
        je      primary_surface_released
        cominvk DDSMain,Release

    primary_surface_released:
        cmp     [DDraw],0
        je      ddraw_released
        cominvk DDraw,Release

    ddraw_released:
        invoke  DestroyWindow, [hwnd]

        invoke  ExitProcess,[msg.wParam]



;функция отрисовки всех окон
proc onPaint 

        invoke WaitForSingleObject, [thread_drawInterface], 0
        cmp   eax, WAIT_TIMEOUT
        je    .finish
          
        invoke  IsIconic, [hwnd]
        mov     [minimized], eax
        test     eax, eax
        jnz     .clientScreen


.startScreen:
        cmp     [curScreen], start_screen
        jne     .serverScreen
        ;mov     [close_flag_buf], 0
        call    drawStart
        jmp     .Skip
        
.serverScreen:
        cmp     [curScreen], server_screen
        jne     .clientScreen
        call    drawAddServer
        jmp     .Skip

.clientScreen:
        cmp     [curScreen], client_screen
        jne     .changeIpScreen
        call    drawAddClient
        jmp     .Skip
        
.changeIpScreen:
        cmp     [curScreen], change_ip_screen
        jne     .mainScreen
        call    drawChangeIp
        jmp     .Skip
        
.mainScreen:
        cmp     [curScreen], main_screen
        jne     .Skip
        invoke  CreateThread, 0, 0, drawMain, 0, 0, 0
        mov     [thread_drawInterface], eax
        ;call    drawMain
        jmp     .Skip
        
;двойная буферизация        
.Skip:

        cmp    [minimized], 0
        jnz     .finish

        
        ;cmp     [close_flag_buf], 0
        ;ja      onPaint
        
        invoke  GetClientRect, [hwnd], rSrc

        invoke  GetWindowRect, [hwnd], rs

        invoke  GetClientRect, [hwnd], rDest

        mov     eax, [rs.left]
        add     eax, 8
        mov     ebx, [rs.top]
        add     ebx, 31
        add     [rDest.left], eax
        add     [rDest.top], ebx
        add     [rDest.right], eax
        add     [rDest.bottom], ebx
        
        cominvk DDSMain, Blt, rDest, [DDSBack], rSrc, DDBLT_WAIT, NULL 
.finish:
        ret
endp




proc  drawChangeIp uses eax ebx
    call    drawStart    
    
    cominvk  DDSBack, GetDC, hdc

    
    invoke  CreatePen, PS_NULL, 1, 0
    mov     [pen], eax
    
    invoke  SelectObject, [hdc], eax
    mov     [tempPen], eax

    invoke  CreateSolidBrush, menu_color
    mov     [brush], eax

    invoke  SelectObject, [hdc],eax; [brush]
    mov     [tempBrush], eax    

    invoke  GetClientRect, [hwnd], rs
    add     [rs.top], 30
    sub     [rs.bottom], 30
    mov     eax, [rs.right]
    sub     eax, [rs.left]
    shr     eax, 1
    sub     eax, add_template_half_width_ip
    mov     [rs.left], eax
    add     eax, add_template_width_ip
    mov     [rs.right], eax
    
    
    invoke   RoundRect, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom], 15, 15
    
   
    mov     eax, [rs.left]
    add     eax, add_template_border_ip  
    mov     [backBtn.x], eax
    mov     ebx, [rs.bottom]
    sub     ebx, 30 + add_template_border_ip
    mov     [backBtn.y], ebx
    add     eax, 120
    mov     [backBtn.right], eax
    add     ebx, 30
    mov     [backBtn.bottom], ebx
   
    
    mov     eax, cells_gap_ip
    mov     ebx, num_cells_ip
    dec     ebx
    mul     ebx
    neg     eax
    add     eax, add_template_width_ip
    sub     eax, add_template_border_ip
    sub     eax, add_template_border_ip
    mov     ebx, num_cells_ip
    xor     edx, edx
    div     ebx
    
    push    eax
    
    invoke  GetClientRect, [hwnd], rs
    add     [rs.top], 60+40
    
    pop     eax
    push    eax
    
    mov     ebx, 10
    mul     ebx
    shr     eax, 3
    mov     ebx, [rs.top]
    add     ebx, eax
    mov     [rs.bottom], ebx
    mov     ebx, 3
    xor     edx, edx
    div     ebx 
    
    
    invoke  CreateFont, eax,\
                            0,\
                            0,\
                            0,\
                            FW_DONTCARE,\
                            FALSE,\
                            FALSE,\
                            FALSE,\
                            ANSI_CHARSET,\
                            OUT_TT_PRECIS,\
                            CLIP_DEFAULT_PRECIS,\
                            PROOF_QUALITY,\
                            DEFAULT_PITCH+ FF_DONTCARE,\
                            _font_name

    mov     [mainFont], eax
    invoke  SelectObject, [hdc], eax
    mov     [tempFont], eax
    invoke   SetBkMode, [hdc], TRANSPARENT
    invoke   SetTextColor, [hdc],0xffffff
    
    
    mov     eax, [rs.right]
    sub     eax, [rs.left]
    shr     eax, 1
    sub     eax, add_template_half_width_ip
    add     eax, add_template_border_ip
    mov     [rs.left], eax
    pop     ebx
    add     eax, ebx
    mov     [rs.right], eax
    add     ebx, cells_gap_ip
    
    push    ebx
    sub   [rs.top], 40
    invoke   DrawText, [hdc], change_server_text, -1, rs, DT_NOCLIP+DT_TOP+DT_LEFT+DT_SINGLELINE
    add   [rs.top], 40
    invoke  SelectObject, [hdc], [tempBrush]
    invoke   DeleteObject, [brush]
    
    invoke  CreateSolidBrush, main_color
    mov     [brush], eax

    invoke  SelectObject, [hdc],eax
    mov     [tempBrush], eax
    
    pop     eax
    
    mov ecx, num_cells_ip
    mov ebx, input_ip
    
    mov edx, 3
.drawCells:
    push  eax
    push  ecx
    push  ebx
    push  ecx
    push  edx
    

   
    invoke   RoundRect, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom], 15, 15
    pop   edx
    pop   ecx
    dec   edx
    jnz   .SkipDot
    
    cmp   ecx, 1
    jz    .SkipDot
    push   [rs.left]
    push   [rs.top]
    push   [rs.right]
    push   [rs.bottom]
    mov    eax, [rs.bottom]
    sub    eax, 4
    mov    [rs.top], eax
    add    eax, 8
    mov    [rs.bottom], eax
    
    mov    eax, [rs.right]
    sub    eax, 2
    mov    [rs.left], eax
    add    eax, 8
    mov    [rs.right], eax
    push   edx
    invoke   Ellipse, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom]
    pop    edx
    pop   [rs.bottom]
    pop   [rs.right]
    pop   [rs.top]
    pop   [rs.left] 
    mov   edx, 3
.SkipDot: 
   
    pop   ebx
    pop   ecx
    
    push  ecx
    push  edx
    mov   eax, num_cells_ip+1
    sub   eax, ecx
    cmp   eax, [server_input_num] 
    jg  .Skip 
    invoke   DrawText, [hdc], ebx, -1, rs, DT_NOCLIP+DT_CENTER+DT_VCENTER+DT_SINGLELINE
.Skip:    
    add   ebx, 4
    pop   edx
    pop   ecx
    pop   eax
    
    add   [rs.left], eax
    add   [rs.right], eax

    dec   ecx
    jnz   .drawCells  
    
    stdcall drawBtn, backBtn 
     
    invoke  SelectObject, [hdc], [tempFont]
    invoke   DeleteObject, [mainFont]
    
    invoke  SelectObject, [hdc], [tempBrush]
    invoke   DeleteObject, [brush]

    invoke  SelectObject, [hdc], [tempPen]
    invoke   DeleteObject, [pen]
    
    cominvk  DDSBack, ReleaseDC, [hdc]
    ret
endp




proc  drawAddServer uses eax ebx
    stdcall    drawAddTemplate, server_input_id
    ret
endp



proc  drawAddClient uses eax

    cmp    [minimized], 0
    jnz     .skipDraw
    
    mov   [server_input_num], num_cells
    stdcall    drawAddTemplate, client_id
    mov   [server_input_num], 0
.skipDraw:
    invoke  GetTickCount
    sub   eax, [last_tick]
    cmp   eax, 1000
    jb    .finish
    add   [last_tick], eax
    stdcall Client.Init, Client.YourIP, [Client.YourPort]
    stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.serverCondition, 4        
    stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], id, 16
    stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], isReady, 4
    stdcall Client.Destroy
    
    cmp [isReady], 0
    je  .finish
    stdcall Server.Init
    mov    [mode], client_mode
    
    
    mov  [curScreen], main_screen
.finish:
    ret
endp




proc    drawMain uses edi

        cmp    [minimized], 0
        jnz     .skipDraw

        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],0

        cominvk  DDSBack, Lock, NULL, ddsd, DDLOCK_WAIT, NULL
        test     eax, eax
        jnz     ddraw_error

        mov     edi, [ddsd.lpSurface]

        invoke  GetClientRect, [hwnd], rs

         push    [rs.right]
         mov     [rs.right], 200

        stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], main_color
         pop       [rs.right]
         sub       [rs.right], 200

        mov     [rs.left], 200

        stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], sec_color

        


        mov         [backBtn.x], 10
        mov         ebx, [rs.bottom]
        sub         ebx, 40
        mov         [backBtn.y], ebx
        add         eax, 120
        mov         [backBtn.right], eax
        add         ebx, 30
        mov         [backBtn.bottom], ebx




        add     [rs.left], 10
        sub     [rs.right], 20
        mov     eax, [rs.right]
        shr     eax, 4
        push    9
        mul     dword [esp]
        pop     ebx
        mov     ebx, [rs.bottom]
        sub     ebx, eax
        shr     ebx, 1
        mov     [rs.top], ebx
        mov     [rs.bottom], eax
        push    eax
        invoke  GetClientRect, [hwnd], rDest
        pop     eax
        add     eax, 60
        cmp     eax, [rDest.bottom]
        jbe     .Skip

        mov     eax, [rDest.bottom]
        sub     eax, 60
        mov     [rs.top], 30
        mov     [rs.bottom], eax
        xor     edx, edx
        push    9
        div     dword [esp]
        pop     ebx
        shl     eax, 4
        mov     ebx, [rs.right]
        sub     ebx, eax
        shr     ebx, 1
        add     [rs.left], ebx
        shl     ebx, 1
        sub     [rs.right], ebx



.Skip:

        mov     eax, [rs.left]
        add     eax, [rs.right]
        mov     [res1080Btn.right],eax
        sub     eax, 45
        mov     [res1080Btn.x],eax
        mov     eax, [rs.top]
        add     eax, [rs.bottom]
        add     eax, 6
        mov     [res1080Btn.y],eax 
        add     eax, 18
        mov     [res1080Btn.bottom],eax
        
        
        mov     eax, [res1080Btn.x]
        sub     eax, 10
        mov     [res720Btn.right],eax
        sub     eax, 45
        mov     [res720Btn.x],eax
        mov     eax, [res1080Btn.y]
        mov     [res720Btn.y],eax 
        add     eax, 18
        mov     [res720Btn.bottom],eax
        
        mov     eax, [res720Btn.x]
        sub     eax, 10
        mov     [res480Btn.right],eax
        sub     eax, 45
        mov     [res480Btn.x],eax
        mov     eax, [res720Btn.y]
        mov     [res480Btn.y],eax 
        add     eax, 18
        mov     [res480Btn.bottom],eax
        
        mov     eax, [res480Btn.x]
        sub     eax, 10
        mov     [res360Btn.right],eax
        sub     eax, 45
        mov     [res360Btn.x],eax
        mov     eax, [res480Btn.y]
        mov     [res360Btn.y],eax 
        add     eax, 18
        mov     [res360Btn.bottom],eax

        ;stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], 0

        cominvk  DDSBack, Unlock, NULL

.skipDraw:        
        invoke  GetTickCount
        mov     [ticks_total], eax     

        cmp   [mode], client_mode
        jne   .server
        push    [lpBuf]
        stdcall GetScreenshot, [hwnd], [rs.left], [rs.top], [rs.right], [rs.bottom]
        pop     [lpBuf]
        jmp   .finish
.server:
        
        stdcall ShowImage, fileName, [rs.left], [rs.top], [rs.right], [rs.bottom]
        ;stdcall drawFullScreenButton, [rs.right], [rs.bottom]
.finish:

        invoke  GetTickCount
        sub     [ticks_total], eax
        neg     [ticks_total]
        
        invoke  wvsprintf, buf_total, buf_format, ticks_total
        

        cmp    [minimized], 0
        jnz     skipDraw2
        

        invoke  CreateFont, 2,\
                            0,\
                            0,\
                            0,\
                            FW_BOLD,\
                            FALSE,\
                            FALSE,\
                            FALSE,\
                            ANSI_CHARSET,\
                            OUT_TT_PRECIS,\
                            CLIP_DEFAULT_PRECIS,\
                            PROOF_QUALITY,\
                            DEFAULT_PITCH+ FF_DONTCARE,\
                            _font_name

        mov      [logoFont], eax


        invoke  SelectObject, [hdc], [logoFont]
        mov     [tempFont], eax

        invoke   SetBkMode, [hdc], TRANSPARENT
        invoke   SetTextColor, [hdc], 0xFFFFFF


        cominvk  DDSBack, GetDC, hdc
        
        cmp       [dev_mode], 0
        je        .skipDev
        
        invoke  GetClientRect, [hwnd], rs

        mov       eax, [rs.right]
        sub       eax, 500
        mov      [rs.left], eax
        mov      [rs.top], 10
        mov      [rs.bottom], 25
        sub      [rs.right],10
        invoke   DrawText, [hdc], text_ticks_total, -1, rs, DT_RIGHT+DT_VCENTER

        mov      [rs.top], 25
        mov      [rs.bottom], 40
        invoke   DrawText, [hdc], text_ticks_compress, -1, rs, DT_RIGHT+DT_VCENTER
        
        mov      [rs.top], 40
        mov      [rs.bottom], 55
        invoke   DrawText, [hdc], text_ticks_send, -1, rs, DT_RIGHT+DT_VCENTER
        
        mov      [rs.top], 55
        mov      [rs.bottom], 70
        invoke   DrawText, [hdc], text_ticks_output, -1, rs, DT_RIGHT+DT_VCENTER
        
        mov      [rs.top], 70
        mov      [rs.bottom], 85
        invoke   DrawText, [hdc], text_x_pos, -1, rs, DT_RIGHT+DT_VCENTER
        
        mov      [rs.top], 85
        mov      [rs.bottom], 100
        invoke   DrawText, [hdc], text_y_pos, -1, rs, DT_RIGHT+DT_VCENTER 
        
        mov     eax, text_lbtn_down
        cmp     [MouseDown], 1
        je      .SkipLbtnState
        mov     eax, text_lbtn_up
.SkipLbtnState:
        mov      [rs.top], 100
        mov      [rs.bottom], 115
        invoke   DrawText, [hdc], eax, -1, rs, DT_RIGHT+DT_VCENTER 
        
        mov      [rs.top], 115
        mov      [rs.bottom], 130
        invoke   DrawText, [hdc], text_img_size, -1, rs, DT_RIGHT+DT_VCENTER
         
        mov      [rs.top], 130
        mov      [rs.bottom], 145
        invoke   DrawText, [hdc], text_min_x, -1, rs, DT_RIGHT+DT_VCENTER
        mov      [rs.top], 145
        mov      [rs.bottom], 160
        invoke   DrawText, [hdc], text_min_y, -1, rs, DT_RIGHT+DT_VCENTER
        mov      [rs.top], 160
        mov      [rs.bottom], 175
        invoke   DrawText, [hdc], text_max_x, -1, rs, DT_RIGHT+DT_VCENTER
        mov      [rs.top], 175
        mov      [rs.bottom], 190
        invoke   DrawText, [hdc], text_max_y, -1, rs, DT_RIGHT+DT_VCENTER
        mov      [rs.top], 190
        mov      [rs.bottom], 205
        invoke   DrawText, [hdc], text_clicks, -1, rs, DT_RIGHT+DT_VCENTER
        
        invoke  SelectObject, [hdc], [tempFont]
        invoke  DeleteObject, [logoFont]

.skipDev:
        

        stdcall     drawBtn, backBtn
        stdcall     drawBtn, res1080Btn
        stdcall     drawBtn, res720Btn
        stdcall     drawBtn, res480Btn
        stdcall     drawBtn, res360Btn
mouse:
        cmp         [MouseControl],0
        jne          .active
        mov         [mouseBtn.color], menu_color
        jmp         .skip
.active:
        mov         [mouseBtn.color], sec_color
.skip:
        stdcall     drawBtn, mouseBtn
        
keyboard:
        cmp         [KeyboardControl],0
        jne          .active
        mov         [keyboardBtn.color], menu_color
        jmp         .skip
.active:
        mov         [keyboardBtn.color], sec_color
.skip:
        stdcall     drawBtn, keyboardBtn
        
efficiency:
        cmp         [dev_mode],0
        jne          .active
        mov         [effBtn.color], menu_color
        jmp         .skip
.active:
        mov         [effBtn.color], sec_color
.skip:
        stdcall     drawBtn, effBtn
        
        
smooth:
        cmp         [SmoothMouse],0
        jne          .active
        mov         [smoothBtn.color], menu_color
        jmp         .skip
.active:
        mov         [smoothBtn.color], sec_color
.skip:
        stdcall     drawBtn, smoothBtn
        
        cominvk  DDSBack, ReleaseDC, [hdc]
skipDraw2:
        ret
endp






proc    drawStart uses edi

        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],0

        cominvk  DDSBack, Lock, NULL, ddsd, DDLOCK_WAIT, NULL
        test     eax, eax
        jnz     ddraw_error

        mov     edi, [ddsd.lpSurface]

        invoke  GetClientRect, [hwnd], rs

        stdcall    drawRect, 0, 0, [rs.right], [rs.bottom], main_color

        push    [rs.right]
        push    [rs.bottom]   
        
        sub     [rs.bottom], 35
        
        
        mov         [settingsBtn.x], 10
        mov         eax, [rs.bottom]
        mov         [settingsBtn.y], eax
        add         eax, 25
        mov         [settingsBtn.bottom], eax
        mov         [settingsBtn.right], 80
        

        sub     [rs.bottom], 120
        sub     [rs.right], 200


        stdcall    drawRect, 100, 75, [rs.right], [rs.bottom], sec_color

        pop         ebx
        pop         eax
        shr         eax, 1
        sub         eax, 180
        mov         [serverBtn.x], eax
        sub         ebx, 145
        mov         [serverBtn.y], ebx
        add         eax, 120
        mov         [serverBtn.right], eax
        add         ebx, 60
        mov         [serverBtn.bottom], ebx
        stdcall     drawBtn, serverBtn
        
        add         eax, 120
        mov         [clientBtn.x], eax
        mov         [clientBtn.bottom], ebx
        add         eax, 120
        mov         [clientBtn.right], eax
        sub         ebx, 60
        mov         [clientBtn.y], ebx
        stdcall     drawBtn, clientBtn
        
        stdcall     drawBtn, settingsBtn

        cominvk  DDSBack, Unlock, NULL




        cominvk  DDSBack, GetDC, hdc


        invoke  CreateFont, 32,\
                            0,\
                            0,\
                            0,\
                            FW_BOLD,\
                            FALSE,\
                            FALSE,\
                            FALSE,\
                            ANSI_CHARSET,\
                            OUT_TT_PRECIS,\
                            CLIP_DEFAULT_PRECIS,\
                            PROOF_QUALITY,\
                            DEFAULT_PITCH+ FF_DONTCARE,\
                            _font_name

        mov      [logoFont], eax


        invoke  SelectObject, [hdc], [logoFont]
        mov     [tempFont], eax

        invoke   SetBkMode, [hdc], TRANSPARENT
        invoke   SetTextColor, [hdc], 0xFFFFFF

        mov      [rs.left], 200
        mov      [rs.top], 120
        mov      [rs.bottom], 160
        invoke   DrawText, [hdc], _title, -1, rs, DT_CENTER+DT_VCENTER

        invoke  SelectObject, [hdc], [tempFont]
        invoke  DeleteObject, [logoFont]

        cominvk  DDSBack, ReleaseDC, [hdc]

        ret
endp






proc WindowProc uses ebx esi edi, hwnd,wmsg,wparam,lparam

        mov     eax,[wmsg]

        cmp     eax,WM_DESTROY
        je      .wmdestroy

        cmp     eax,WM_CREATE
        je      .wmcreate

        cmp     eax,WM_LBUTTONDOWN
        je      .wmlbtndown
        
        cmp     eax,WM_LBUTTONUP
        je      .wmlbtnup
        
        cmp     eax,WM_RBUTTONDOWN
        je      .wmrbtndown
        
        cmp     eax,WM_RBUTTONUP
        je      .wmrbtnup

        cmp     eax,WM_KEYDOWN
        je      .wmkeydown

        cmp     eax,WM_PAINT
        je      .wmpaint

        cmp     eax,WM_CLOSE
        je      .wmclose

        cmp     eax,WM_GETMINMAXINFO
        je      .wmgetminmaxinfo

        cmp     eax,WM_ERASEBKGND
        je      .wmerasebg
        
        cmp     eax,WM_CHAR
        je      .wmchar
        
        cmp     eax,WM_SETFOCUS
        je      .wmsetfocus
        
        cmp     eax,WM_KILLFOCUS
        je      .wmkillfocus
        
        cmp     eax,WM_KEYUP
        je      .wmkeyup

  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish

  .wmcreate:
               
        jmp     .finish  
        
  .wmsetfocus:
        mov     [window_active], 1
        jmp     .finish
        
  .wmkillfocus:
        mov     [window_active], 0
        jmp     .finish

  .wmdestroy:
        invoke WaitForSingleObject, [thread_drawInterface], 1000000
        invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke  PostQuitMessage,0
        xor     eax,eax
        jmp     .finish




  .wmlbtndown: 
        cmp     [mode], server_mode
        jne     .CheckButtons
        
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000 
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        ;invoke WaitForSingleObject, [thread_output], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        mov     [MouseDown], 1
        
        inc     [MouseTotal]
        mov     ebx, [MouseCur]
        invoke  GlobalAlloc, GHND, sizeof.MouseListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [MouseCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     dword[ebx], 1
        mov     dword[ebx+4], 1
               
.CheckButtons:        
        mov     eax, [lparam]
        mov     [p], eax
        stdcall checkButtons, [lparam]
        jmp     .finish




   .wmlbtnup: 
        cmp     [mode], server_mode
        jne     .finish
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        mov     [MouseDown], 0
        
        inc     [MouseTotal]
        mov     ebx, [MouseCur]
        invoke  GlobalAlloc, GHND, sizeof.MouseListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [MouseCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     dword[ebx], 1
        mov     dword[ebx+4], 0
        
        jmp     .finish
        
        
        
        
        
   .wmrbtnup: 
        cmp     [mode], server_mode
        jne     .finish
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        mov     [MouseDown], 0
        
        inc     [MouseTotal]
        mov     ebx, [MouseCur]
        invoke  GlobalAlloc, GHND, sizeof.MouseListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [MouseCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     dword[ebx], 0
        mov     dword[ebx+4], 0
        
        jmp     .finish
        
        
        
        
   .wmrbtndown: 
        cmp     [mode], server_mode
        jne     .finish
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        mov     [MouseDown], 0
        
        inc     [MouseTotal]
        mov     ebx, [MouseCur]
        invoke  GlobalAlloc, GHND, sizeof.MouseListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [MouseCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     dword[ebx], 0
        mov     dword[ebx+4], 1
        
        jmp     .finish
        
        
        
        
   .wmkeyup:
        cmp     [mode], server_mode
        jne     .finish
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        mov     [InputSymbol], 0
        
        inc     [KeyboardTotal]
        mov     ebx, [KeyboardCur]
        invoke  GlobalAlloc, GHND, sizeof.KeyboardListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [KeyboardCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     eax, [wparam]
        mov     dword[ebx], eax
        mov     dword[ebx+4], 0

        jmp     .finish





  .wmkeydown:
        cmp     [wparam],VK_ESCAPE
        je     .wmdestroy
        
        cmp     [mode], server_mode
        jne     .finish
        ;invoke WaitForSingleObject, [thread_drawInterface], 1000000
        ;invoke WaitForSingleObject, [thread_recieve], 1000000
        invoke WaitForSingleObject, [thread_control], 1000000
        
        inc     [KeyboardTotal]
        mov     ebx, [KeyboardCur]
        invoke  GlobalAlloc, GHND, sizeof.KeyboardListElement
        mov     [ebx+12], eax
        invoke  GlobalLock, eax
        mov     [ebx+8], eax
        mov     [KeyboardCur], eax
        mov     ebx, eax
        mov     dword[ebx+8], 0
        mov     dword[ebx+12], 0
        mov     eax, [wparam]
        mov     [InputSymbol], eax
        mov     dword[ebx], eax
        mov     dword[ebx+4], 1
        jmp     .finish
  
  
  
  
  .wmchar:
        cmp     [curScreen], server_screen
        jne     .change_ip
        stdcall     inputID,[wparam]
 .change_ip:
        cmp     [curScreen], change_ip_screen
        jne     .finish
        stdcall     changeIP,[wparam]
        jmp     .finish 
        
        
        

  .wmpaint:
        call    onPaint
        jmp     .finish

  .wmgetminmaxinfo:
        mov     ebx, [lparam]
        mov     dword [ebx+24], 780
        mov     dword [ebx+28], 512
        jmp     .finish

   .wmerasebg:
        jmp     .finish


  .wmclose:
        jmp     end_loop


  .finish:

        ret
endp


;обработка нажатий клавиш при вводе id
proc    inputID, wparam

.enter_button:
    cmp   [wparam], 0x0D
    jne   .backspace
    
    cmp   [server_input_num], num_cells
    jne   .finish
    
    stdcall Client.Init, Client.YourIP, [Client.YourPort]
    stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.sendID.server, 4        
    stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], id, 16
    stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], ip_addr, 32
    stdcall Client.Destroy
    
    cmp   [ip_addr], 0
    jz    .error_ip
    
    
    mov   [curScreen], main_screen
    stdcall Client.Init, ip_addr, [Server.YourPort]
    
    mov    [mode], server_mode
    
    mov   [server_input_num], 0
    
    jmp   .finish
.error_ip:
    mov   [server_input_num], 0
    jmp   .finish
.backspace:
    cmp   [wparam], 0x08
    jne   .other
    
    mov   eax, [server_input_num]
    test  eax, eax
    jz    .finish
    dec   [server_input_num]
    
    jmp   .finish
.other:

    cmp   [wparam],'0'
    jb    .finish
    cmp   [wparam], '9'
    ja    .finish 
    mov   eax, [server_input_num]
    cmp   eax, num_cells
    je    .finish
    shl   eax, 2
    inc   [server_input_num]
    mov   bx, word[wparam] 
    mov   word[id+eax], bx
    
.finish:   
    ret
endp







;обработка нажатий клавиш при вводе id
proc    changeIP, wparam

.enter_button:
    cmp   [wparam], 0x0D
    jne   .backspace
    
    cmp   [server_input_num], num_cells_ip
    jne   .finish
    
    mov   ecx, 4
    mov   esi, Client.YourIP
    mov   edx, 0
.outerloop:
    mov   edi, 3
    mov   ebx, 0
.innerloop:
    mov   ax,[input_ip+edx] 
    cmp   al, '0'
    jne   .Skip
    cmp   ebx, 0
    jne   .Skip
    cmp   edi, 1
    je    .Skip
    add   edx, 4
    dec   edi
    jmp   .innerloop
    
.Skip:    
    mov   [esi], al
    mov   ebx, 1
    
    add   edx, 4
    add   esi, 1
    dec   edi
    jnz   .innerloop
    
    jl    .innerloop
    mov   byte[esi],'.'
    add   esi, 1
    loop  .outerloop 
    dec   esi
    mov   byte[esi],0
    
    mov   [curScreen], start_screen 
    mov   [server_input_num], 0  
  
    jmp   .finish
.backspace:
    cmp   [wparam], 0x08
    jne   .other
    
    mov   eax, [server_input_num]
    test  eax, eax
    jz    .finish
    dec   [server_input_num]
    
    jmp   .finish
.other:

    cmp   [wparam],'0'
    jb    .finish
    cmp   [wparam], '9'
    ja    .finish 
    mov   eax, [server_input_num]
    cmp   eax, num_cells_ip
    je    .finish
    shl   eax, 2
    inc   [server_input_num]
    mov   bx, word[wparam] 
    mov   word[input_ip+eax], bx
    
.finish:   
    ret
endp








;обработка нажатия кнопок
proc    checkButtons uses eax, lparam

        cmp    [minimized], 0
        jnz     finish

        movsx   eax, word [lparam]
        movsx   ebx, word [lparam+2]




startScreen:
        cmp     [curScreen], start_screen
        jne     settingsScreen

.serverBtn:
        cmp     eax, [serverBtn.x]
        jb      .clientBtn
        cmp     ebx, [serverBtn.y]
        jb      .clientBtn
        cmp     eax, [serverBtn.right]
        ja      .clientBtn
        cmp     ebx, [serverBtn.bottom]
        ja      .clientBtn


        mov     [curScreen], server_screen

        jmp     finish



.clientBtn:
        cmp     eax, [clientBtn.x]
        jb      .settingsBtn
        cmp     ebx, [clientBtn.y]
        jb      .settingsBtn
        cmp     eax, [clientBtn.right]
        ja      .settingsBtn
        cmp     ebx, [clientBtn.bottom]
        ja      .settingsBtn


        mov     [curScreen], client_screen

                ;инициализация уникального id клиента
        stdcall Client.Init, Client.YourIP, [Client.YourPort]
        
        invoke  CreateFile, fileSettings, GENERIC_READ+GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        mov    [hfileSettings], eax
        invoke  GetLastError
        cmp     eax, 183
        je      .exists
.getID:
        ;получение id от сервера
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.getId, 4        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], your_id, 16
        mov [temp], 0
        invoke  WriteFile, [hfileSettings], your_id, 16, temp, NULL
        jmp .skip
.exists:
        ;чтение id из файла настроек
        invoke   ReadFile, [hfileSettings], your_id, 16, 0, NULL       
.skip: 
        invoke   CloseHandle, [hfileSettings]
        stdcall Client.Destroy
        
        
        mov     ecx, 4
        mov     ebx, 0        
.copy_id:
        mov     eax, dword[your_id+ebx]
        mov     dword [id+ebx], eax
        add     ebx, 4
        loop    .copy_id
        
        
        
        stdcall Client.Init, Client.YourIP, [Client.YourPort]
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.sendID.client, 4        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], your_id, 16
        stdcall Client.Destroy

        jmp     finish
        
        
.settingsBtn:
        cmp     eax, [settingsBtn.x]
        jb      finish
        cmp     ebx, [settingsBtn.y]
        jb      finish
        cmp     eax, [settingsBtn.right]
        ja      finish
        cmp     ebx, [settingsBtn.bottom]
        ja      finish
        
        
        mov   ecx, 4
        mov   esi, Client.YourIP
        mov   edx, 0
.outerloop:
        mov   edi, 3
.innerloop:
         
        mov   al, [esi]
        
        cmp   al, '.'
        je    .dot
        cmp   al, 0
        je    .dot
        jmp   .notdot

.dot:
        push  ecx
        mov   ecx, 4
        sub   ecx, edi
.dotloop:
        mov   al, '0'
        xor   ah, ah
        mov   [input_ip+edx], ax
        sub   edx, 4
        dec   esi      
        loop  .dotloop
        inc   esi
        pop   ecx
        
        push  edi
.incedx:
        add   edx, 4
        dec   edi
        jnz   .incedx
        
        add   edx, 4
        
        pop   edi
        
        mov   eax, 3
        sub   eax, edi
        mov   edi, eax

        jmp  .innerloop
        
.notdot:        
        xor   ah, ah
        mov   [input_ip+edx], ax
    
        add   edx, 4
        add   esi, 1
        dec   edi
        jnz   .innerloop
    
        jl    .innerloop
        add   esi, 1
.endloop:
        loop  .outerloop 
        
        mov   [server_input_num], num_cells_ip


        mov     [curScreen], change_ip_screen

        jmp     finish
        
    
    
    
        
settingsScreen:
        cmp     [curScreen], change_ip_screen
        jne     mainScreen
        
        .backBtn:
        cmp     eax, [backBtn.x]
        jb      finish
        cmp     ebx, [backBtn.y]
        jb      finish
        cmp     eax, [backBtn.right]
        ja      finish
        cmp     ebx, [backBtn.bottom]
        ja      finish


        mov     [curScreen], start_screen
        mov     [server_input_num], 0

        jmp     finish        





mainScreen:
        cmp     [curScreen], main_screen
        jne     serverScreen
        
.smoothBtn:
        cmp     [mode], server_mode
        jne     .mouseBtn
        cmp     eax, [smoothBtn.x]
        jb      .mouseBtn
        cmp     ebx, [smoothBtn.y]
        jb      .mouseBtn
        cmp     eax, [smoothBtn.right]
        ja      .mouseBtn
        cmp     ebx, [smoothBtn.bottom]
        ja      .mouseBtn

        xor     [SmoothMouse], 1        

        jmp     finish
        
.mouseBtn:
        cmp     [mode], server_mode
        jne     .keyboardBtn
        cmp     eax, [mouseBtn.x]
        jb      .keyboardBtn
        cmp     ebx, [mouseBtn.y]
        jb      .keyboardBtn
        cmp     eax, [mouseBtn.right]
        ja      .keyboardBtn
        cmp     ebx, [mouseBtn.bottom]
        ja      .keyboardBtn

        xor     [MouseControl], 1        

        jmp     finish
        
.keyboardBtn:
        cmp     [mode], server_mode
        jne     .effBtn
        cmp     eax, [keyboardBtn.x]
        jb      .effBtn
        cmp     ebx, [keyboardBtn.y]
        jb      .effBtn
        cmp     eax, [keyboardBtn.right]
        ja      .effBtn
        cmp     ebx, [keyboardBtn.bottom]
        ja      .effBtn

        xor     [KeyboardControl], 1        

        jmp     finish
        
.effBtn:
        cmp     eax, [effBtn.x]
        jb      .backBtn
        cmp     ebx, [effBtn.y]
        jb      .backBtn
        cmp     eax, [effBtn.right]
        ja      .backBtn
        cmp     ebx, [effBtn.bottom]
        ja      .backBtn

        xor     [dev_mode], 1        

        jmp     finish

.backBtn:
        cmp     eax, [backBtn.x]
        jb      .res360Btn
        cmp     ebx, [backBtn.y]
        jb      .res360Btn
        cmp     eax, [backBtn.right]
        ja      .res360Btn
        cmp     ebx, [backBtn.bottom]
        ja      .res360Btn

        mov     [close_flag], 1
        call    onPaint
        mov     [curScreen], start_screen
        mov     [server_input_num], 0
        

        jmp     finish
        
.res360Btn:
        cmp     eax, [res360Btn.x]
        jb      .res480Btn
        cmp     ebx, [res360Btn.y]
        jb      .res480Btn
        cmp     eax, [res360Btn.right]
        ja      .res480Btn
        cmp     ebx, [res360Btn.bottom]
        ja      .res480Btn

        cmp     [cur_res], res360
        je      finish
        
        invoke WaitForSingleObject, [thread_drawInterface], 100000
        
        mov     [change_flag], 1 
        mov     [cur_res], res360
        
        cmp     [mode], server_mode
        je      finish
        stdcall recreateBMP        

        jmp     finish
        
.res480Btn:
        cmp     eax, [res480Btn.x]
        jb      .res720Btn
        cmp     ebx, [res480Btn.y]
        jb      .res720Btn
        cmp     eax, [res480Btn.right]
        ja      .res720Btn
        cmp     ebx, [res480Btn.bottom]
        ja      .res720Btn

        cmp     [cur_res], res480
        je      finish
        
        invoke WaitForSingleObject, [thread_drawInterface], 100000
        
        mov     [change_flag], 1
        mov     [cur_res], res480
        
        cmp     [mode], server_mode
        je      finish
        stdcall recreateBMP        

        jmp     finish
        
.res720Btn:
        cmp     eax, [res720Btn.x]
        jb      .res1080Btn
        cmp     ebx, [res720Btn.y]
        jb      .res1080Btn
        cmp     eax, [res720Btn.right]
        ja      .res1080Btn
        cmp     ebx, [res720Btn.bottom]
        ja      .res1080Btn

        cmp     [cur_res], res720
        je      finish
        
        invoke WaitForSingleObject, [thread_drawInterface], 100000
        
        mov     [change_flag], 1
        mov     [cur_res], res720
        
        cmp     [mode], server_mode
        je      finish
        stdcall recreateBMP        

        jmp     finish
        
.res1080Btn:
        cmp     eax, [res1080Btn.x]
        jb      finish
        cmp     ebx, [res1080Btn.y]
        jb      finish
        cmp     eax, [res1080Btn.right]
        ja      finish
        cmp     ebx, [res1080Btn.bottom]
        ja      finish

        cmp     [cur_res], res1080
        je      finish
        
        invoke WaitForSingleObject, [thread_drawInterface], 100000
        
        mov     [change_flag], 1
        mov     [cur_res], res1080
        
        cmp     [mode], server_mode
        je      finish
        stdcall recreateBMP        

        jmp     finish





serverScreen:
        cmp     [curScreen], server_screen
        jne     clientScreen
        
        .backBtn:
        cmp     eax, [backBtn.x]
        jb      finish
        cmp     ebx, [backBtn.y]
        jb      finish
        cmp     eax, [backBtn.right]
        ja      finish
        cmp     ebx, [backBtn.bottom]
        ja      finish


        mov     [curScreen], start_screen
        mov     [server_input_num], 0

        jmp     finish
        
        
        
        
clientScreen:
        cmp     [curScreen], client_screen
        jne     finish
        
        .backBtn:
        cmp     eax, [backBtn.x]
        jb      finish
        cmp     ebx, [backBtn.y]
        jb      finish
        cmp     eax, [backBtn.right]
        ja      finish
        cmp     ebx, [backBtn.bottom]
        ja      finish
        
        mov   [server_input_num], 0


        mov     [curScreen], start_screen 
        stdcall Client.Init, Client.YourIP, [Client.YourPort]
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], Request.closeID, 4        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], your_id, 16
        stdcall Client.Destroy                                 


finish:
        ret
endp




section '.data' data readable writeable

  _class TCHAR 'FDDRAW32',0
  _button_class TCHAR 'BUTTON',0
  _button_text TCHAR 'OK',0
  _title TCHAR 'Welcome to BleenControl',0

  _error TCHAR 'Startup failed.',0
  _ddraw_error TCHAR 'Direct Draw initialization failed.',0
  _font_name   TCHAR 'Roboto'

  serverBtnText TCHAR 'Connect', 0
  clientBtnText TCHAR 'Allow',13,10,'connection', 0

  backBtnText  TCHAR 'Back', 0

  fileName     TCHAR 'FRAME.BMP', 0
  fileName1    db    'FRAME.BMP', 0
  fileSettings  TCHAR 'Settings_id.txt',0
  
  id  TCHAR     '1',0,'2',0,'3',0,'4',0
  input_ip  TCHAR     '1',0,'2',0,'7',0,'0',0,'0',0,'0',0,'0',0,'0',0,'0',0,'0',0,'0',0,'1',0
  your_id  TCHAR     '1',0,'2',0,'3',0,'4',0
  client_id TCHAR   'Your personal ID:',0
  server_input_id TCHAR  'Input the id of the client:',0
  change_server_text TCHAR 'Your server ip:',0
  settingsText TCHAR 'Settings', 0
  
  host_name db 256 dup (?)
  ip_addr   db 32 dup (0)
  
  res360text  TCHAR '360p', 0
  res480text  TCHAR '480p', 0
  res720text  TCHAR '720p', 0
  res1080text  TCHAR '1080p', 0
  
  effBtnText TCHAR 'Show efficiency', 0
  mouseBtnText TCHAR 'Mouse', 0
  keyboardBtnText TCHAR 'Keyboard', 0
  smoothText TCHAR 'Smooth mouse', 0
  off_text TCHAR 'Off', 0
  on_text TCHAR 'On', 0
  
  


section '.bss' readable writeable

  server_input_num  dd  0
  
  hwnd dd  ?
  hCheckBoxDev dd ?

  wc WNDCLASS 0,\ ; стиль окна по умолчанию             ; структура, определяющая класс окна
              WindowProc,\ ; функция окна
              0,\     ; дескриптор приложения
              0,\     ; дескриптор пиктограммы
              NULL,\  ;
              NULL,\  ;
              NULL,\  ;
              COLOR_BTNFACE+1,\  ; цвет заливки окна
              NULL,\  ;
              _class  ; имя класса окна

  msg MSG

  ddsd  DDSURFACEDESC
  ddscaps DDSCAPS
  
  host  hostent

  DDraw DirectDraw
  DDSMain DirectDrawSurface
  DDSBack DirectDrawSurface
  DDSPicture DirectDrawSurface
  DDClipper DirectDrawClipper
  
  hdcdd dd ?

  hdc dd ?
  hbr dd ?
  
  hfileSettings dd ?

  sWidth dd 1920
  sHeight dd 1080
  rs   RECT
  rSrc RECT
  rDest RECT
  p     POINT
  last_tick dd ?
  curScreen dd 0
  tempFont  dd 0
  tempBrush dd 0
  tempPen   dd 0
  temp      dd 0
  temp1     dd 0

  logoFont      dd ?
  mainFont      dd ?
  pen           dd ?
  brush         dd ?

  serverBtn BUTTON 0, 0, 0, 0, serverBtnText, main_color, 0xFFFFFF, 18
  clientBtn BUTTON 0, 0, 0, 0, clientBtnText, main_color, 0xFFFFFF, 18
  backBtn  BUTTON 0, 0, 0, 0, backBtnText, main_color, 0xFFFFFF, 18
  res360Btn BUTTON 0, 0, 0, 0, res360text, menu_color, 0xFFFFFF, 14
  res480Btn  BUTTON 0, 0, 0, 0, res480text, menu_color, 0xFFFFFF, 14
  res720Btn  BUTTON 0, 0, 0, 0, res720text, menu_color, 0xFFFFFF, 14
  res1080Btn  BUTTON 0, 0, 0, 0, res1080text, main_color, 0xFFFFFF, 14
  settingsBtn  BUTTON 0, 0, 0, 0, settingsText, sec_color, 0xFFFFFF, 14
  mouseBtn  BUTTON 40, 40, 160, 70, mouseBtnText, menu_color, 0xFFFFFF, 15
  keyboardBtn  BUTTON 40, 80, 160, 110, keyboardBtnText, menu_color, 0xFFFFFF, 15
  effBtn  BUTTON 40, 120, 160, 150, effBtnText, menu_color, 0xFFFFFF, 15
  smoothBtn  BUTTON 40, 160, 160, 190, smoothText, menu_color, 0xFFFFFF, 15
  

  bmpScreen BITMAP
  bmfHeader BITMAPFILEHEADER
  bi        BITMAPINFOHEADER
  hbm       dd ?
  hdcPicture dd ?
  pBmp       dd ?
  hbmDest    dd ?
  pBmpDest   dd ?
  hFile      dd ?
  
  bi_res     BITMAPINFOHEADER
  hDIB_res dd ?
  lpbitmap_res dd ?
  hbmScreen_res dd ?
  hdcMemDC_res dd ?

  Compressor  dd ?
  Decompressor  dd ?
  Compressor1  dd ?
  Decompressor1  dd ?
  hTempBuf dd 0
  lpTempBuf dd 0
  
  hdcScreen dd ?
  hdcMemDC dd ?
  hbmScreen dd ?
  dwBmpSize dd ?
  hDIB dd ?
  lpbitmap dd ?
  hDIB_temp dd ?
  lpbitmap_temp dd ?
  dwSizeOfDIB dd ?
  
  
  



section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          ddraw,'DDRAW.DLL',\
          gdi,'GDI32.DLL',\
          compress,'CABINET.DLL',\
          wsock32,  'WSOCK32.DLL',\
          ws2tcpip, 'WS2_32.DLL',\
          stdlib, 'libc.lib'
          

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\wsock32.inc'

  import ws2tcpip,\
         inet_ntop,'inet_ntop'
              

  import ddraw,\
         DirectDrawCreate,'DirectDrawCreate',\
         DDCopyBitmap,'DDCopyBitmap'

  import gdi,\
         GetObject, 'GetObjectA',\
         CreateFont,'CreateFontA',\
         TextOut, 'TextOutW',\
         SetBkColor, 'SetBkColor',\
         SetTextColor, 'SetTextColor',\
         RoundRect, 'RoundRect',\
         SelectObject, 'SelectObject',\
         DeleteObject, 'DeleteObject',\
         Rectangle, 'Rectangle',\
         SetBrushColor, 'SetDCBrushColor',\
         SetBkMode, 'SetBkMode',\
         CreateSolidBrush, 'CreateSolidBrush',\
         CreatePen, 'CreatePen',\
         GetDeviceCaps, 'GetDeviceCaps',\
         CreateCompatibleDC, 'CreateCompatibleDC',\
         SetStretchBltMode, 'SetStretchBltMode',\
         StretchBlt,'StretchBlt',\
         BitBlt, 'BitBlt',\
         CreateCompatibleBitmap,'CreateCompatibleBitmap',\
         GetDIBits, 'GetDIBits',\
         SetDIBits, 'SetDIBits',\
         Ellipse,'Ellipse'

  import compress,\
         CreateCompressor, 'CreateCompressor',\
         CreateDecompressor, 'CreateDecompressor',\
         Compress, 'Compress',\
         Decompress, 'Decompress'
