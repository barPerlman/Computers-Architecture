global drone
extern dronesArr,current_co,isGameOver,currAlphaDeg,currAlphaRad
extern generate_random_number,resume,convert_deg_to_rad
extern t                                            ; amount of required destroys to win
extern mayDestroy
extern limit                                        ; initializer for generate_random_number function
extern current_co,prev_co,printf

section .bss
align 16
    randomizedAngle: resq 1     ;new calculated alpha
    randomizedDistance: resq 1  ;new calculated dist.
    tempX:  resq 1 
    tempY:  resq 1
    
section .data
align 16
    ;strings of messages to print in case of winning
    format_string_sscanf: db "Drone id %d:  I am a winner",10,0
    initDeg: dq 360
    zero: dq 0
    hundred: dq 100

section .text

drone:

    mov ebx, [prev_co]
    sub ebx, 3                                      ; correct the drone index in second struct 
    cmp [t], dword 0                                ; check if the t we accepted is 0 
    je .win
   
    ; (dromei=current_co-3=cors[i+3])
    ; calculate random angle 
    mov dword [limit],0
    mov dword [limit], 120                          ; for angle generation between -60-60
    call generate_random_number
    fstp qword [randomizedAngle]                    ; randomizedAngle=new generated delta alpha
    
    ; calculate random distance 
    mov dword [limit],0
    mov dword [limit],50                            ; for fp dist. generation between 0-50
    call generate_random_number
    fstp qword [randomizedDistance]                 ; randomizedDistance = new generated delta d
    
    ; calculate a new drone position
    ; 1. change the current angle to be α + ∆α, keeping the angle between [0, 360] 
.update_angle:
    fld qword [randomizedAngle]                     ; st0 = randomizedAngle
    mov esi, dword [dronesArr]
    mov edi, [esi + ebx*4]                          ; update current co-routine's stack top
    mov esi,[edi+16]		                        ; esp = address of coi stack
    fld qword [edi+16]                              ; st1 = randomizedAngle, st0 = old alpha
    faddp                                           ; st1 = st0+st1-> pop-> st0=st1 before pop
    ;check if need to fix the angle into bounds
    fild qword [initDeg]
    fcomip
    jb .sub_from_res_angle                          ; correct because its bigger than 360
    
    ;check if the new angle is negative
    fild qword [zero]
    fcomip
    ja .add_to_res_angle                            ; correct because its lower than 0
    
    ;the result angle is in bounds so go to motion calculation
    jmp .update_angle_in_structure
        
.sub_from_res_angle:    
    fild qword [initDeg]
    fsub                                            ; st0 = new alpha-360
    jmp .update_angle_in_structure
    
.add_to_res_angle:
    fild qword [initDeg]
    fadd                                            ; st0 = new alpha+360
    
;update drone new alpha angle
.update_angle_in_structure:
    fst qword [edi+16]                              ; update the drone's alpha
    
;move ∆d at the direction defined by the current angle, wrapping around the torus if needed
.move:   
    ;get alpha in radians in aim to use it inside trigo's functions
    fstp qword [currAlphaDeg]                       ; pop new alpha into currAlphaDeg as argument to convertion to radians func.
    call convert_deg_to_rad                         ; after this func is called we assume the angle in readians is at currAlphaRad
    
    ;calculate cos(alpha-rad)
    fld qword [currAlphaRad]
    fcos                                            ; st0 = cos(st0)
    fld qword [randomizedDistance]
    fmul                                            ; st0 = cos(alpha)*d 
    fadd qword [edi]                                ;(st0 = cos(alpha)*d +xPos) = x2
    fstp qword [tempX]                              ; xPos = x2 and pop(updated xPos)
    
    ;calculate sin(alpha-rad)
    fld qword [currAlphaRad]
    fsin                                            ; st0 = sin(st0)
    fld qword [randomizedDistance]
    fmul                                            ; st0 = cos(alpha)*d 
    fadd qword [edi+8]                              ; (st0 = cos(alpha)*d +yPos) = y2
    fstp qword [tempY]                              ; xPos = x2 and pop(updated xPos)
    
;now that we have the new position (x2,y2) we need to correct torus is needed
.check_right_border:
    fld qword [tempX]
    fild qword [hundred]
    fcomip
    
    jnb .check_left_border
    ;fix xPos in torus way
    fild qword [hundred]
    fsub                                            ; st0 = xPos-100 correct x to the left
    jmp .check_upper_border
    
.check_left_border:   
    fld qword [tempX]
    fild qword [zero]
    fcomip
    jna .check_upper_border
    ;fix xPos in torus way
    fild qword [hundred]
    fadd                                            ; st0 = xPos+100 correct x to the right

.check_upper_border:
    fstp qword [edi]                                ; update xPos with the new x
    fld qword [tempY]
    fild qword [zero]
    fcomip
    jna .check_lower_border
    ;fix yPos in torus way
    fild qword [hundred]
    fadd                                            ; st0 = xPos+100 correct y down the screen
    jmp .finish_fix_location
        
.check_lower_border:
    fld qword [tempY]
    fild qword [hundred]
    fcomip
    jnb .finish_fix_location
    ;fix yPos in torus way
    fild qword [hundred]
    fsub                                            ; st0 = xPos-100 correct x to the left    
.finish_fix_location:
    fstp qword [edi+8]                              ; update yPos with the new y
    
    ;check id can destroy- call to may destroy with ebx=drone id and get 1=true in eax or 0=false
    call mayDestroy
    ;mayDestroy==true
    cmp eax,0   
    jne .destroy
    ;else
    jmp .back_to_scheduler
    
.destroy:
    mov edx,[edi+24]
    inc edx                                         ; t++
    mov dword [edi+24], edx
    ;check if game should be over
    cmp dword edx,[t]                               ; amount of destroys for current drone is t
    jne .new_target                                 ; not game over so make a new_target
    ;game over
    ;print winning string
.win: 
    inc ebx
    push ebx
    push format_string_sscanf
    call printf
    add esp, 8
    dec ebx
    ;change game state to game over
    mov dword [isGameOver],1
    jmp .back_to_scheduler
    
.new_target:
    ;resume(target)
    add ebx,3
    mov dword [prev_co],ebx
    mov ebx,2   
    call resume
    jmp drone
    
.back_to_scheduler:
    ;resume(scheduler)
    add ebx,3
    mov dword [prev_co],ebx
    xor ebx,ebx
    call resume
    jmp drone
