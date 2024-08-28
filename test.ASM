
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

        cominvk DDSBack,SetClipper,\
                [DDClipper]
        test    eax, eax
        jnz     ddraw_error

        invoke  GetSystemMetrics, 78
       ; invoke   SystemParametersInfoA,0x0030,0 , rs,0
       ; mov      eax, [rs.right]
       ; sub      eax, [rs.left]
        and     eax, -16
        mov     [sWidth], eax
        shl     [sWidth], 2

        invoke  GetTickCount
        mov     [last_tick],eax




  msg_loop:    ; цикл сообщений
               ; необработанные сообщения извлекаются из очереди и передаются ОС
               ; затем ОС вызывает функцию окна
        invoke  GetMessage,msg,NULL,0,0
        cmp     eax,1
        jb      end_loop
        jne     msg_loop
        invoke  TranslateMessage,msg
        invoke  DispatchMessage,msg
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
        jne     .mainScreen
        call    drawStart
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




proc    drawMain uses edi

        mov     [ddsd.dwSize],sizeof.DDSURFACEDESC
        mov     [ddsd.dwFlags],0

        cominvk  DDSBack, Lock, NULL, ddsd, DDLOCK_WAIT, NULL
        test     eax, eax
        jnz     ddraw_error

        mov     edi, [ddsd.lpSurface]

        invoke  GetClientRect, [hwnd], rs

       ; shr     [rs.right], 2
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
       ; stdcall    drawLine, 100, 100, [coords], [coords+4], 0xFF0000
       ; stdcall    drawCircle, [coords], [coords+4], 20, 0xFF0000

        pop         ebx
        pop         eax
        shr         eax, 1
        sub         eax, 60
        mov         [startBtn.x], eax
        sub         ebx, 115
        mov         [startBtn.y], ebx
        add         eax, 120
        mov         [startBtn.right], eax
        add         ebx, 30
        mov         [startBtn.bottom], ebx
        stdcall     drawBtn, startBtn

        cominvk  DDSBack, Unlock, NULL

       ; mov     eax, [ddsd.dwSrcVBHandle]
       ; mov     [hdc], eax



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

       ; invoke   SetBkColor, [hdc], 0x343536
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




proc    drawBtn uses edi eax ebx, button


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



        mov     ebx, [button]

        cominvk  DDSBack, GetDC, hdc

        invoke  CreatePen, PS_NULL, 1, 0
        mov     [pen], eax

        invoke  CreateSolidBrush, [ebx+24]
        mov     [brush], eax

        invoke  SelectObject, [hdc],eax; [brush]
        mov     [tempBrush], eax

        invoke  SelectObject, [hdc], [pen]
        mov     [tempPen], eax

        invoke  SelectObject, [hdc], [mainFont]
        mov     [tempFont], eax


        invoke   RoundRect, [hdc], [ebx], [ebx+4], [ebx+8], [ebx+12], 5, 5

        mov      eax, [ebx]
        mov      [rSrc.left], eax
        mov      eax, [ebx+4]
        mov      [rSrc.top], eax

        mov      eax, [ebx+8]
        mov      [rSrc.right], eax
        mov      eax, [ebx+12]
        mov      [rSrc.bottom], eax

       ; invoke   SetBkColor, [hdc], [ebx+28]
        invoke   SetBkMode, [hdc], TRANSPARENT
        invoke   SetTextColor, [hdc],[ebx+20]

        invoke   DrawText, [hdc], [ebx+16], -1, rSrc, DT_CENTER+DT_VCENTER+DT_SINGLELINE


        invoke  SelectObject, [hdc], [tempFont]
        invoke  DeleteObject, [mainFont]

        invoke  SelectObject, [hdc], [tempBrush]
        invoke   DeleteObject, [brush]

        invoke  SelectObject, [hdc], [tempPen]
        invoke   DeleteObject, [pen]


        cominvk  DDSBack, ReleaseDC, [hdc]

        ret
endp








proc drawArc uses edi eax ecx, x, y, r, start, finish, color



        ret
endp

proc drawCircle uses edi eax ecx edx esi, x, y, r, color

        mov     eax, [y]
        sub     eax, [r]
        mul     [sWidth]
        add     edi, eax
        mov     eax, [x]
        sub     eax, [r]
        shl     eax, 2
        add     edi, eax

        mov     eax, [r]
        neg     eax
        mov     [x], eax
        mov     [y], eax
        neg     eax
        mov     ecx, eax      ;r

        mov     eax, [r]
        mul     [r]
        mov     ebx, eax      ;r-square

.Start:

@@:
        mov     eax, [x]
        mul     [x]
        mov     esi, eax
        mov     eax, [y]
        mul     [y]
        add     esi, eax
        cmp     esi, ebx
        jg      .Skip
        mov     eax, [color]
        mov     dword [edi], eax
.Skip:
        inc     [x]
        add     edi, 4
        cmp     [x], ecx
        jl      @b

        shl     ecx, 1
        sub     [x], ecx
        inc     [y]
        add     edi, [sWidth]
        shl     ecx, 2
        sub     edi, ecx
        shr     ecx, 3

        cmp     [y], ecx
        jl      .Start

        ret
endp


;edi - address of the surface
;+8  - x
;+12 - y
;+16 - width
;+20 - height
;+24 - color

proc drawRect uses edi eax ecx, x, y, width, height, color

        shl     dword [x], 2
        add     edi, [x]

        mov     eax, [y]
        mul     [sWidth]
        add     edi, eax

        mov     eax, [color]

.OuterLoop:
        mov     ecx,[width]
@@:
        stosd
        loop    @b

        add     edi, [sWidth]

        shl     dword [width], 2
        sub     edi, [width]
        shr     dword [width], 2

        dec     dword [height]

        jnz     .OuterLoop

        ret
endp




proc drawLine uses edi eax ebx ecx edx esi, x1, y1, x2, y2, color

        push    edi

        mov     eax, [y1]
        cmp     eax, [y2]
        jle     .Skip
        xchg    eax, [y2]
        xchg    [y1], eax
        mov     eax, [x1]
        xchg    eax, [x2]
        xchg    [x1], eax
.Skip:

        mov     eax, [y1]
        mul     [sWidth]
        add     edi, eax
        shl     [x1], 2
        add     edi, [x1]
        shr     [x1], 2

        mov     ecx, [y2]
        sub     ecx, [y1]   ;delta y (A)

        mov     ebx, [x1]
        sub     ebx, [x2]   ;delta x (B)

        mov     eax, ecx
        cdq
        or      edx, 1
        mov     esi, edx      ;sign A
        mul     esi
        mov     ecx, eax

        mov     eax, ebx
        cdq
        or      edx, 1
        mov     ebx, edx      ;sign B
        mul     ebx
        mov     dx, si
        shl     dx, 8
        mov     dl, bl
        shl     dl, 2
        mov     ebx, eax

        pop     esi
        push    edx
        mov     eax, [y2]
        mul     [sWidth]
        add     esi, eax
        shl     [x2], 2
        add     esi, [x2]

        mov     [x2], esi
        xor     esi, esi

        ;dl - sign B - x1
        ;dh - sign A
        ;ebx - B
        ;ecx - A
        ;edi - coords
        ;x2 - end coords
        ;esi - f
        ;eax - color

.StartDraw:
        pop     edx
        movsx   eax, dl
        mov     [x1], eax

        mov     eax, [color]

        mov     [edi], eax


.Compare:      ;B-A


        cmp    ebx, ecx
        jg     Above45


Below45:           ;B<A
.StartLoop:

        add     esi, ebx

        cmp     esi, 0
        jle     .Skip

        sub     esi, ecx
        sub     edi, [x1]

.Skip:
        cmp     dh, 0
        js      .CheckSign
        add     edi, [sWidth]
        jmp     .Draw
.CheckSign:
        sub     edi, [sWidth]

.Draw:
        mov     [edi], eax

        cmp     edi, [x2]
        jb      .StartLoop


        jmp     EndProc



Above45:
.StartLoop:

        add     esi, ecx

        cmp     esi, 0
        jle     .Skip

        sub     esi, ebx

        cmp     dh, 0
        js      .CheckSign
        add     edi, [sWidth]
        jmp     .Skip
.CheckSign:
        sub     edi, [sWidth]

.Skip:

        sub     edi, [x1]

.Draw:
        mov     [edi], eax

        cmp     edi, [x2]
        jb      .StartLoop

EndProc:

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

.startScreen:
        cmp     [curScreen], start_screen
        jne     .mainScreen

.startBtn:
        cmp     eax, [startBtn.x]
        jb      .finish
        cmp     ebx, [startBtn.y]
        jb      .finish
        cmp     eax, [startBtn.right]
        ja      .finish
        cmp     ebx, [startBtn.bottom]
        ja      .finish


        mov     [curScreen], main_screen

        jmp     .finish


.mainScreen:
        cmp     [curScreen], main_screen
        jne     .finish

.backBtn:
        cmp     eax, [backBtn.x]
        jb      .finish
        cmp     ebx, [backBtn.y]
        jb      .finish
        cmp     eax, [backBtn.right]
        ja      .finish
        cmp     ebx, [backBtn.bottom]
        ja      .finish


        mov     [curScreen], start_screen

        jmp     .finish



.finish:
        ret
endp




section '.data' data readable writeable

  _class TCHAR 'FDDRAW32',0
  _title TCHAR 'Welcome to BleenControl',0

  _error TCHAR 'Startup failed.',0
  _ddraw_error TCHAR 'Direct Draw initialization failed.',0
  _font_name   TCHAR 'Roboto'

  startBtnText TCHAR 'Start', 0

  backBtnText  TCHAR 'Back', 0


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

  logoFont      dd ?
  mainFont      dd ?
  pen           dd ?
  brush         dd ?

  startBtn BUTTON 0, 0, 0, 0, startBtnText, 0xFFFFFF, 0x2e2e2e
  backBtn  BUTTON 0, 0, 0, 0, backBtnText, 0xFFFFFF, 0x343536





section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
          user32,'USER32.DLL',\
          ddraw,'DDRAW.DLL',\
          gdi,'GDI32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'

  import ddraw,\
         DirectDrawCreate,'DirectDrawCreate'

  import gdi,\
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
         GetDeviceCaps, 'GetDeviceCaps'
