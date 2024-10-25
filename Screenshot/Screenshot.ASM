proc    ShowImage uses eax ebx ecx edx, filename, left, top, right, bottom
        mov     [temp], 0
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], temp, 4
        
        invoke  GlobalAlloc, GHND, [temp]
        mov     [hbm], eax
        invoke  GlobalLock, eax
        mov     [pBmp], eax
        
        mov     [temp1], 0
.repit:        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], [pBmp], [temp]
        add     [pBmp], eax
        sub     [temp], eax
        add     [temp1], eax
        
        cmp     [temp], 0
        ja      .repit
        
        mov      eax, [temp1]
        sub     [pBmp], eax
        mov      [temp], eax
        
        mov     [temp1], 0
        invoke  Decompress, [Decompressor], [pBmp], [temp], NULL, 0, temp1

        invoke  GlobalAlloc, GHND, [temp1]
        mov     [hbmDest], eax

        invoke  GlobalLock, eax
        mov    [pBmpDest], eax
                
        invoke  Decompress, [Decompressor], [pBmp], [temp], [pBmpDest], [temp1], temp1

        invoke  GlobalUnlock, [hbm]
        invoke  GlobalFree, [hbm]
        
        
        
        cominvk DDSBack, GetDC, hdc
        invoke  CreateCompatibleBitmap, [hdc], 1920, 1080
        mov     [hbm], eax
        invoke  GetObject, eax, sizeof.BITMAP, bmpScreen
        mov     eax, [bmpScreen.bmBits]
        
        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], bi, sizeof.BITMAPINFOHEADER
        
        invoke  SetDIBits, [hdc], [hbm], 0, 1080, [pBmpDest], bi ,0

        invoke   CreateCompatibleDC, [hdc]
        mov      [hdcPicture], eax
        invoke  SelectObject, [hdcPicture], [hbm]

        invoke  SetStretchBltMode, [hdc], HALFTONE
        invoke  StretchBlt, [hdc], [left], [top], [right], [bottom], [hdcPicture], 0, 0, 1920, 1080, SRCCOPY

        cominvk  DDSBack, ReleaseDC, [hdc]
        
        
        invoke  GlobalUnlock, [hbmDest]
        invoke  GlobalFree, [hbmDest]
        
        invoke  DeleteObject, [hbm]
        
        invoke  DeleteObject, [hdcPicture]

        stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], close_flag_buf, 4
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], close_flag, 4
        
        mov      eax, [close_flag_buf]
        add      eax, [close_flag]
        cmp     eax, 0
        je      .finish
        
        stdcall Client.Destroy
        
        mov     [curScreen], start_screen
        mov     [close_flag], 0
        mov     [close_flag_buf], 0
.finish:
        ret
endp





proc    GetScreenshot uses eax ebx edx, hwnd, left, top, right, bottom

        mov     ebx, esp

        invoke  GetDC, NULL
        push    eax  ;hdcScreen   -4

        invoke  CreateCompatibleDC, [ebx-4]
        push    eax  ;hdcMemDC    -8

        invoke  CreateCompatibleBitmap, [ebx-4], 1920, 1080

        push    eax  ;hbmScreen   -12

        invoke  SelectObject, [ebx-8], eax

        invoke  BitBlt, [ebx-8], 0, 0, 1920, 1080, [ebx-4], 0, 0, SRCCOPY

        invoke  SetThreadDpiAwarenessContext, -2
        invoke  GetCursorPos, p
        invoke  DrawIcon, [ebx-8], [p.x], [p.y], [wc.hCursor]
        invoke  SetThreadDpiAwarenessContext, -1

        cominvk DDSBack, GetDC, hdc
        invoke  SetStretchBltMode, [hdc], HALFTONE
        invoke  StretchBlt, [hdc], [left], [top], [right], [bottom], [ebx-8], 0, 0, 1920, 1080, SRCCOPY
        cominvk DDSBack, ReleaseDC, [hdc]

        invoke  GetObject, [ebx-12], sizeof.BITMAP, bmpScreen


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
        push    eax  ;dwBmpSize   -16

        invoke  GlobalAlloc, GHND, eax
        push    eax  ;hDIB        -20

        invoke  GlobalLock, eax
        push    eax  ;lpbitmap    -24


        invoke  GetDIBits, [ebx-4], [ebx-12], 0, [bmpScreen.bmHeight], eax, bi, 0


        push    dword [ebx-16]    ;dwSizeOfDIB -28 new value
        
        mov     eax, sizeof.BITMAPFILEHEADER
        add     eax, sizeof.BITMAPINFOHEADER
        add     [ebx-16], eax
        mov     [bmfHeader.bfOffBits], eax
        mov     eax, [ebx-16]
        mov     [bmfHeader.bfSize], eax
        mov     [bmfHeader.bfType], 0x4D42

        push    0       ;CompressedBufferSize -32

        sub     ebx, 32
        invoke  Compress, [Compressor], [ebx+8], [bmfHeader.bfSize], 0, 0, ebx
        add     ebx, 32

        invoke  GlobalAlloc, GHND, [ebx-32]
        push    eax  ;hBuf        -36

        invoke  GlobalLock, eax
        push    eax  ;lpBuf    -40

        push    0    ;CompressedDataSize   -44

        sub     ebx, 44
        invoke  Compress, [Compressor], [ebx+20], [bmfHeader.bfSize], eax, [ebx+12], ebx
        add     ebx, 44

        ;invoke  WriteFile, [ebx-28], bmfHeader, sizeof.BITMAPFILEHEADER, [ebx-36], NULL
        ;invoke  WriteFile, [ebx-28], bi, sizeof.BITMAPINFOHEADER, [ebx-36], NULL
        ;invoke  WriteFile, [ebx-28], [ebx-48], [ebx-52], [ebx-36], NULL

        ;stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], [bmfHeader], sizeof.BITMAPFILEHEADER
        ;stdcall ws_socket_get_msg_tcp, [Client.hTCPSock], [bi], sizeof.BITMAPINFOHEADER
        push    ebx
        sub     ebx, 44
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], ebx, 4
        add     ebx, 44
        pop     ebx
        
        
        mov     [temp1], 0
.repit:        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], [ebx-40], [ebx-44]
        add     [ebx-40], eax
        sub     [ebx-44], eax
        add     [temp1], eax
        
        cmp     dword[ebx-44], 0
        ja      .repit
        
        
        mov      eax, [temp1]
        sub      [ebx-40], eax
        mov      [ebx-44], eax
        
        stdcall ws_socket_send_msg_tcp, [Client.hTCPSock], bi, sizeof.BITMAPINFOHEADER

        invoke  GlobalUnlock, [ebx-40]
        invoke  GlobalFree, [ebx-40]

        invoke  GlobalUnlock, [ebx-24]
        invoke  GlobalFree, [ebx-24]
        ;invoke  CloseHandle, [ebx-28]

        invoke  DeleteObject, [ebx-12]
        invoke  DeleteObject, [ebx-8]
        invoke  ReleaseDC,NULL, [ebx-4]
        
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

        mov     esp, ebx
        ret

endp