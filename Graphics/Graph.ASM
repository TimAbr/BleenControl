proc drawFullScreenButton, right, bottom
  mov       eax, [right]
  sub       eax, 40
  mov       ebx, [bottom]
  sub       ebx, 10
  mov       ecx, eax
  add       ecx, 10
  mov       edx, ebx 
  stdcall  drawLine, eax, ebx, ecx, edx, 0 

  ret
endp


proc    drawAddTemplate uses eax ebx ecx edx, show_str

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
    sub     eax, add_template_half_width
    add     eax, add_template_border
    mov     [rs.left], eax
    pop     ebx
    add     eax, ebx
    mov     [rs.right], eax
    add     ebx, cells_gap
    
    push    ebx
    sub   [rs.top], 40
    invoke   DrawText, [hdc], [show_str], -1, rs, DT_NOCLIP+DT_TOP+DT_LEFT+DT_SINGLELINE
    add   [rs.top], 40
    invoke  SelectObject, [hdc], [tempBrush]
    invoke   DeleteObject, [brush]
    
    invoke  CreateSolidBrush, main_color
    mov     [brush], eax

    invoke  SelectObject, [hdc],eax
    mov     [tempBrush], eax
    
    pop     eax
    
    mov ecx, num_cells
    mov ebx, id
.drawCells:
    push  eax
    push  ecx
    push  ebx
   
    invoke   RoundRect, [hdc], [rs.left], [rs.top], [rs.right], [rs.bottom], 15, 15
    pop   ebx
    pop   ecx
    push  ecx
    mov   eax, num_cells+1
    sub   eax, ecx
    cmp   eax, [server_input_num] 
    jg  .Skip 
    invoke   DrawText, [hdc], ebx, -1, rs, DT_NOCLIP+DT_CENTER+DT_VCENTER+DT_SINGLELINE
.Skip:    
    add   ebx, 4
    pop   ecx
    pop   eax
    
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






proc    drawBtn uses edi eax ebx, button
        locals
            mainf  dd   ?
            tempf  dd   ?
            b      dd   ?
            tb     dd   ?
            p      dd   ?
            tp     dd   ?
        endl

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

        mov     [mainf], eax



        mov     ebx, [button]

        cominvk  DDSBack, GetDC, hdc

        invoke  CreatePen, PS_NULL, 1, 0
        mov     [p], eax
        
        invoke  SelectObject, [hdc], eax
        mov     [tp], eax

        invoke  CreateSolidBrush, [ebx+24]
        mov     [b], eax
        
        invoke  SelectObject, [hdc], eax
        mov     [tb], eax


        invoke  SelectObject, [hdc], [mainf]
        mov     [tempf], eax


        invoke   RoundRect, [hdc], [ebx], [ebx+4], [ebx+8], [ebx+12], 5, 5

        mov      eax, [ebx]
        mov      [rSrc.left], eax
        mov      eax, [ebx+4]
        mov      [rSrc.top], eax

        mov      eax, [ebx+8]
        mov      [rSrc.right], eax
        mov      eax, [ebx+12]
        mov      [rSrc.bottom], eax

        invoke   SetBkMode, [hdc], TRANSPARENT
        invoke   SetTextColor, [hdc],[ebx+20]

        invoke   DrawText, [hdc], [ebx+16], -1, rSrc, DT_CALCRECT+DT_CENTER
       
        mov      ecx, [rSrc.bottom]
        sub      ecx, [rSrc.top]
        
        mov      eax, [ebx+12]
        sub      eax, [ebx+4]
        
        sub      eax, ecx
        shr      eax, 1
        add      [rSrc.top], eax
        add      [rSrc.bottom], eax
        
        mov      eax, [ebx]
        mov      [rSrc.left], eax
        mov      eax, [ebx+8]
        mov      [rSrc.right], eax
        
        invoke   DrawText, [hdc], [ebx+16], -1, rSrc, DT_CENTER+DT_NOCLIP


        invoke  SelectObject, [hdc], [tempf]
        invoke  DeleteObject, [mainf]

        invoke  SelectObject, [hdc], [tb]
        invoke   DeleteObject, [b]
        
        invoke  SelectObject, [hdc], [tp]
        invoke   DeleteObject, [p]


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