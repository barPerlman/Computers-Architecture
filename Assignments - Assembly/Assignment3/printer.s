global printer
extern resume,printf
extern xPos,yPos,N,dronesArr
extern current_co,prev_co

section .bss

section .data
    print_float: db "%.2f",0
    print_int: db "%d",0
    print_comma: db ",",0
    print_newLine: db "",10,0
    temp1: dd 0
    temp2: dd 0

section .text

printer:
    mov dword [prev_co],1
    call    print_game_board
    xor     ebx, ebx
    call    resume
    jmp     printer

print_game_board:
    xor ebx,ebx
    xor ecx,ecx
    mov ecx,1                                   ; ecx = id of current drone to print
    mov [temp1], ecx
    ;print target at first - x,y\n
    ;print x
    fld qword [xPos]
    sub esp, 8
    fstp qword [esp]
    push print_float
    call printf
    add esp, 12

    ;print ,
    push print_comma
    call printf
    add esp,4
    
    ;print y
    fld qword [yPos]
    sub esp, 8
    fstp qword[esp]
    push print_float
    call printf
    add esp, 12
    
    ;print newline
    push print_newLine
    call printf
    add esp,4
    
;print drones  
.print_drones_loop:
    cmp dword ecx, [N]
    jg .finish                                                      ; if i>num of drones
    ;i<=num of drones
    ;print drone(i)'s state, 1<=i<=N -  id,xi,xi,alphai,ti
    
    ;print id:
    mov ecx,[temp1]
    push ecx    ;push i
    push print_int                                                  ; int format
    call printf
    add esp,8
    
    ;print ,
    push print_comma
    call printf
    add esp,4
    
    ;print xi
    xor edx,edx
    mov ecx, [temp1]
    mov edx,ecx
    sub edx,1                                                       ; edx = index of curr drone in dronesArr
    mov [temp2], edx
    mov esi, dword [dronesArr]
    mov edi, [esi + edx*4] 
 
    fld qword [edi+0]
    sub esp, 8
    fstp qword[esp]
    push print_float
    call printf
    add esp, 12
    
    ;print ,
    push print_comma
    call printf
    add esp,4
    
    ;print yi:
    fld qword [edi+8]
    sub esp, 8
    fstp qword[esp]
    push print_float
    call printf
    add esp, 12
    
    ;print ,
    push print_comma
    call printf
    add esp,4
    
    ;print alphai
    fld qword [edi+16]
    sub esp, 8
    fstp qword[esp]
    push print_float
    call printf
    add esp, 12
    
    ;print ,
    push print_comma
    call printf
    add esp,4
    
    ;print ti- num of destroys
    xor eax, eax
    mov eax,[edi+24]                                        ;eax get alphai
    push dword eax                                          ;push t
    push print_int
    call printf
    add esp,8
    
    ;print newline
    push print_newLine
    call printf
    add esp,4
    
        
.updates_to_next_drone:
    mov ecx, [temp1]
    mov edx, [temp2]
    add ecx,1                                               ;i++
    inc edx
    mov [temp1], ecx
    mov [temp2], edx
    jmp .print_drones_loop
    
.finish:
        ret
