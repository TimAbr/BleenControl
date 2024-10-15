proc    ShowImage uses eax ebx ecx edx, filename, left, top, right, bottom



        invoke  CreateFile, fileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
        mov    [hFile], eax


        invoke  GetFileSizeEx, eax, temp

        invoke  GlobalAlloc, GHND, [temp]
        mov     [hbm], eax

        invoke  GlobalLock, eax
        mov    [pBmp], eax

        invoke   ReadFile, [hFile], [pBmp], [temp], 0, NULL

        mov      eax, [pBmp]
        mov      ebx, [eax + 2]
        sub      ebx, sizeof.BITMAPFILEHEADER+sizeof.BITMAPINFOHEADER
        sub      [temp], sizeof.BITMAPFILEHEADER+sizeof.BITMAPINFOHEADER
        add      eax, sizeof.BITMAPFILEHEADER+sizeof.BITMAPINFOHEADER

        push    eax
        invoke  Decompress, [Decompressor], eax, [temp], NULL, 0, temp1

        invoke  GlobalAlloc, GHND, [temp1]
        mov     [hbmDest], eax

        invoke  GlobalLock, eax
        mov    [pBmpDest], eax

        cominvk  DDSBack, GetDC, hdc


        add     [pBmp], sizeof.BITMAPFILEHEADER+sizeof.BITMAPINFOHEADER

        pop     eax
        invoke  Decompress, [Decompressor], eax, [temp], [pBmpDest], [temp1], temp1
        invoke  GetLastError



        invoke  GlobalUnlock, [pBmp]
        invoke  GlobalFree, [hbm]


        invoke  CreateCompatibleBitmap, [hdc], 1920, 1080
        mov     [hbm], eax
        invoke  GetObject, eax, sizeof.BITMAP, [pBmpDest]
        invoke  SetDIBits, [hdc], [hbm], 0, 1080, [pBmpDest], bi ,0

        invoke   CreateCompatibleDC, [hdc]
        mov      [hdcPicture], eax
        invoke  SelectObject, [hdcPicture], [hbm]

        invoke  SetStretchBltMode, [hdc], HALFTONE
        invoke  StretchBlt, [hdc], [left], [top], [right], [bottom], [hdcPicture], 0, 0, 1920, 1080, SRCCOPY



        invoke  GlobalUnlock, [pBmpDest]
        invoke  GlobalFree, [hbmDest]

        cominvk  DDSBack, ReleaseDC, [hdc]
        invoke  DeleteObject, [hdcPicture]

        invoke  CloseHandle, [hFile]

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

;
        invoke  CreateFile, fileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
        push    eax  ;hFile       -28

        push    dword [ebx-16] ;dwSizeOfDIB -32
        mov     eax, sizeof.BITMAPFILEHEADER
        add     eax, sizeof.BITMAPINFOHEADER
        add     [ebx-16], eax
        mov     [bmfHeader.bfOffBits], eax
        mov     eax, [ebx-16]
        mov     [bmfHeader.bfSize], eax
        mov     [bmfHeader.bfType], 0x4D42

        push    0       ;dwBytesWritten -36
        push    0       ;CompressedBufferSize -40

        sub     ebx, 40
        invoke  Compress, [Compressor], [ebx+16], [bmfHeader.bfSize], 0, 0, ebx
        add     ebx, 40

        invoke  GlobalAlloc, GHND, [ebx-40]
        push    eax  ;hBuf        -44

        invoke  GlobalLock, eax
        push    eax  ;lpBuf    -48

        push    0    ;CompressedDataSize   -52

        sub     ebx, 52
        invoke  Compress, [Compressor], [ebx+28], [bmfHeader.bfSize], eax, [ebx+12], ebx
        add     ebx, 52

        invoke  WriteFile, [ebx-28], bmfHeader, sizeof.BITMAPFILEHEADER, [ebx-36], NULL
        invoke  WriteFile, [ebx-28], bi, sizeof.BITMAPINFOHEADER, [ebx-36], NULL
      ;  invoke  WriteFile, [ebx-28], [ebx-24], [ebx-16], [ebx-36], NULL
        invoke  WriteFile, [ebx-28], [ebx-48], [ebx-52], [ebx-36], NULL

        invoke  GlobalUnlock, [ebx-44]
        invoke  GlobalFree, [ebx-44]

        invoke  GlobalUnlock, [ebx-20]
        invoke  GlobalFree, [ebx-20]
        invoke  CloseHandle, [ebx-28]

        invoke  DeleteObject, [ebx-12]
        invoke  DeleteObject, [ebx-8]
        invoke  ReleaseDC,NULL, [ebx-4]

        mov     esp, ebx
        ret

endp