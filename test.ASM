
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

        invoke  SetThreadDpiAwarenessContext, -2
        invoke  GetSystemMetrics,  SM_CXSCREEN
        mov     [sWidth], eax
        shl     [sWidth], 2
        invoke  SetThreadDpiAwarenessContext, -1

        invoke  GetTickCount
        mov     [last_tick],eax

        invoke  CreateCompressor, 4, NULL, Compressor
        invoke  CreateDecompressor, 4, NULL, Decompressor
        
        
        ;stdcall Client.Init, Client.YourIP, [Client.YourPort]
        ;stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], fileName1, 9
        ;stdcall Client.Destroy
        
        


  msg_loop:    ; цикл сообщений
               ; необработанные сообщения извлекаются из очереди и передаются ОС
               ; затем ОС вызывает функцию окна
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      no_message
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
        jmp     msg_loop

  no_message:
        cmp     [curScreen], main_screen
        jne     msg_loop
        invoke  GetTickCount
        mov     ebx,eax
        sub     ebx,[last_tick]
        cmp     ebx,20
        jb      msg_loop
        add     [last_tick],20
        call    onPaint

  sleep:
        invoke  WaitMessage
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




proc onPaint

.startScreen:
        cmp     [curScreen], start_screen
        jne     .serverScreen
        call    drawStart
        jmp     .Skip
        
.serverScreen:
        cmp     [curScreen], server_screen
        jne     .clientScreen
        call    drawAddServer
        jmp     .Skip

.clientScreen:
        cmp     [curScreen], client_screen
        jne     .mainScreen
        call    drawAddClient
        jmp     .Skip
        
.mainScreen:
        cmp     [curScreen], main_screen
        jne     .Skip
        call    drawMain
        jmp     .Skip
.Skip:

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

        ret
endp


proc    drawAddTemplate uses eax

    call    drawStart
    
    
    invoke  CreateFont, 18,\
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
    
    
    cominvk  DDSBack, GetDC, hdc

    
    invoke  CreatePen, PS_NULL, 1, 0
    mov     [pen], eax
    
    invoke  SelectObject, [hdc], eax
    mov     [tempPen], eax

    invoke  CreateSolidBrush, 0x1f1f1f
    mov     [brush], eax

    invoke  SelectObject, [hdc],eax; [brush]
    mov     [tempBrush], eax

    invoke  SelectObject, [hdc], [mainFont]
    mov     [tempFont], eax

    invoke  GetClientRect, [hwnd], rs
    add     [rs.top], 30
    sub     [rs.bottom], 30
    mov     eax, [rs.right]
    sub     eax, [rs.left]
    shr     eax, 1
    sub     eax, add_template_half_width
    mov     [rs.left], eax
    add     eax, add_template_width
    mov     [rs.right], eax
    
    
    invoke   RoundRect, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom], 15, 15
    
   
    mov     eax, [rs.left]
    add     eax, add_template_border  
    mov     [backBtn.x], eax
    mov     ebx, [rs.bottom]
    sub     ebx, 30 + add_template_border
    mov     [backBtn.y], ebx
    add     eax, 120
    mov     [backBtn.right], eax
    add     ebx, 30
    mov     [backBtn.bottom], ebx
   
    
    mov     eax, cells_gap
    mov     ebx, num_cells
    dec     ebx
    mul     ebx
    neg     eax
    add     eax, add_template_width
    sub     eax, add_template_border
    sub     eax, add_template_border
    mov     ebx, num_cells
    xor     edx, edx
    div     ebx
    
    push    eax
    
    invoke  GetClientRect, [hwnd], rs
    add     [rs.top], 60
    
    pop     eax
    push    eax
    
    mov     ebx, 10
    mul     ebx
    shr     eax, 3
    mov     ebx, [rs.top]
    add     ebx, eax
    mov     [rs.bottom], ebx
    
    mov     eax, [rs.right]
    sub     eax, [rs.left]
    shr     eax, 1
    sub     eax, add_template_half_width
    add     eax, add_template_border
    mov     [rs.left], eax
    pop     ebx
    add     eax, ebx
    mov     [rs.right], eax
    add     ebx, cells_gap
    
    push    ebx
    
    invoke  SelectObject, [hdc], [tempBrush]
    invoke   DeleteObject, [brush]
    
    invoke  CreateSolidBrush, 0x2e2e2e
    mov     [brush], eax

    invoke  SelectObject, [hdc],eax
    mov     [tempBrush], eax
    
    pop     eax
    mov ecx, num_cells
    mov ebx, id
.drawCells:
    push  ecx
    push  eax
    push  ebx
    invoke   RoundRect, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom], 15, 15
    pop   ebx
    invoke   DrawText, [hdc], ebx, -1, rs, DT_NOCLIP+DT_CENTER+DT_VCENTER+DT_SINGLELINE
    add   ebx, 4
    pop   eax
    pop   ecx
    add   [rs.left], eax
    add   [rs.right], eax

    loop .drawCells  
    
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
    call    drawAddTemplate
    ret
endp



proc  drawAddClient uses eax
    call    drawAddTemplate
    ret
endp




proc    drawMain uses edi

        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],0

        cominvk  DDSBack, Lock, NULL, ddsd, DDLOCK_WAIT, NULL
        test     eax, eax
        jnz     ddraw_error

        mov     edi, [ddsd.lpSurface]

        invoke  GetClientRect, [hwnd], rs

         push    [rs.right]
         mov     [rs.right], 200

        stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], 0x2e2e2e
         pop       [rs.right]
         sub       [rs.right], 200

        mov     [rs.left], 200

        stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], 0x343536






        mov         [backBtn.x], 10
        mov         ebx, [rs.bottom]
        sub         ebx, 40
        mov         [backBtn.y], ebx
        add         eax, 120
        mov         [backBtn.right], eax
        add         ebx, 30
        mov         [backBtn.bottom], ebx
        stdcall     drawBtn, backBtn




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
        add     eax, 20
        cmp     eax, [rDest.bottom]
        jbe     .Skip

        mov     eax, [rDest.bottom]
        sub     eax, 20
        mov     [rs.top], 10
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

        stdcall    drawRect, [rs.left], [rs.top], [rs.right], [rs.bottom], 0

        cominvk  DDSBack, Unlock, NULL


        stdcall GetScreenshot, [hwnd], [rs.left], [rs.top], [rs.right], [rs.bottom]


        ;stdcall ShowImage, fileName, [rs.left], [rs.top], [rs.right], [rs.bottom]

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

        stdcall    drawRect, 0, 0, [rs.right], [rs.bottom], 0x2e2e2e

        push    [rs.right]
        push    [rs.bottom]

        sub     [rs.bottom], 150
        sub     [rs.right], 200


        stdcall    drawRect, 100, 75, [rs.right], [rs.bottom], 0x343536

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
        je      .wmlbtn

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

  .defwndproc:
        invoke  DefWindowProc,[hwnd],[wmsg],[wparam],[lparam]
        jmp     .finish

  .wmcreate:
        xor     eax,eax
        jmp     .finish

  .wmdestroy:

        invoke  PostQuitMessage,0
        xor     eax,eax
        jmp     .finish

  .wmlbtn:
        mov     eax, [lparam]
        mov     [p], eax
        stdcall checkButtons, [lparam]
        jmp     .finish

  .wmkeydown:
        cmp     [wparam],VK_ESCAPE
        jne     .finish
        jmp     .wmdestroy

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


proc    checkButtons uses eax, lparam

        movsx   eax, word [lparam]
        movsx   ebx, word [lparam+2]




startScreen:
        cmp     [curScreen], start_screen
        jne     mainScreen

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
        jb      finish
        cmp     ebx, [clientBtn.y]
        jb      finish
        cmp     eax, [clientBtn.right]
        ja      finish
        cmp     ebx, [clientBtn.bottom]
        ja      finish


        mov     [curScreen], client_screen

        jmp     finish





mainScreen:
        cmp     [curScreen], main_screen
        jne     serverScreen

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


        mov     [curScreen], start_screen

        jmp     finish


finish:
        ret
endp




section '.data' data readable writeable

  _class TCHAR 'FDDRAW32',0
  _title TCHAR 'Welcome to BleenControl',0

  _error TCHAR 'Startup failed.',0
  _ddraw_error TCHAR 'Direct Draw initialization failed.',0
  _font_name   TCHAR 'Roboto'

  serverBtnText TCHAR 'Connect', 0
  clientBtnText TCHAR 'Allow',13,10,'connection', 0

  backBtnText  TCHAR 'Back', 0

  fileName     TCHAR 'FRAME.BMP', 0
  fileName1    db    'FRAME.BMP', 0
  
  id  TCHAR     'a',0,'b',0,'c',0,'d',0
  
  


section '.bss' readable writeable

  hwnd dd  ?

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

  DDraw DirectDraw
  DDSMain DirectDrawSurface
  DDSBack DirectDrawSurface
  DDSPicture DirectDrawSurface
  DDClipper DirectDrawClipper

  ps PAINTSTRUCT
  hdc dd ?
  hbr dd ?

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

  serverBtn BUTTON 0, 0, 0, 0, serverBtnText, 0xFFFFFF, 0x2e2e2e
  clientBtn BUTTON 0, 0, 0, 0, clientBtnText, 0xFFFFFF, 0x2e2e2e
  backBtn  BUTTON 0, 0, 0, 0, backBtnText, 0xFFFFFF, 0x343536

  bmpScreen BITMAP
  bmfHeader BITMAPFILEHEADER
  bi        BITMAPINFOHEADER
  hbm       dd ?
  hdcPicture dd ?
  pBmp       dd ?
  hbmDest    dd ?
  pBmpDest   dd ?
  hFile      dd ?

  picture  TCHAR 'FRAME.JPEG', 0

  gdiPlusToken dd ?
  gdipsi      dd 20 dup (?)
  Compressor  dd ?
  Decompressor  dd ?


  CLSID   dw  0x557c, 0xf401,0x1a04,0x11d3,0x9a73,0x0000,0xf81e,0xf32e
  ; db  0x59, 0x84, 0xFF, 0xE0, 0x28, 0xD4, 0x11, 0xCF, 0xAE, 0x66, 0x08, 0x00, 0x2B, 0x2E, 0x12, 0x62
  ; db 128 dup (?)
  ; db  0x55, 0x7c,0xf4, 0x06, 0x1a,0x04, 0x11,0xd3, 0x9a,0x73,0x00,0x00,0xf8,0x1e,0xf3,0x2e
  ; dw  0x557c, 0xf401,0x1a04,0x11d3,0x9a73,0x0000,0xf81e,0xf32e
  ; db  0x59, 0x84, 0xFF, 0xE0, 0x28, 0xD4, 0x11, 0xCF, 0xAE, 0x66, 0x08, 0x00, 0x2B, 0x2E, 0x12, 0x62




section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          ddraw,'DDRAW.DLL',\
          gdi,'GDI32.DLL',\
          compress,'CABINET.DLL',\
          wsock32,  'WSOCK32.DLL'
          

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\wsock32.inc'


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
         SetDIBits, 'SetDIBits'

  import gdiplus,\
         GdiplusStartup, 'GdiplusStartup',\
         Bitmap, 'GdipCreateBitmapFromHBITMAP',\
         SaveImage, 'GdipSaveImageToFile',\
         GdipLoadImageFromFile, 'GdipLoadImageFromFile'

  import compress,\
         CreateCompressor, 'CreateCompressor',\
         CreateDecompressor, 'CreateDecompressor',\
         Compress, 'Compress',\
         Decompress, 'Decompress'
