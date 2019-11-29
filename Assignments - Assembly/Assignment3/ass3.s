global generate_random_number,limit,xPos,yPos,randRes,isGameOver,k,N,t,main
global resume,end_co
global dronesArr,currAlphaDeg,currAlphaRad,convert_deg_to_rad,mayDestroy
extern printer, scheduler, drone, createTarget
extern printf
extern fprintf
extern calloc
extern free
extern sscanf
global current_co,prev_co                                   ; current co-routine

; macro that starts a function
%macro startFun 0
    push ebp
    mov ebp, esp
%endmacro

; macro that ends a function
%macro endFun 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

; macro that calls sscanf
%macro runSscanf 0
    push format_string_sscanf
    push eax
    call sscanf
    add esp,12
%endmacro

; macro that calls sscanf for floats
%macro runSscanfFloat 0
    push format_string_sscanf_float
    push eax
    call sscanf
    add esp,12
%endmacro

; macro that calls sscanf for floats
%macro getIntArgs 1
    finit 
    fld dword [tempArg]
    frndint
    fistp dword [%1]
%endmacro

; macro that calls calloc
%macro runCalloc 2
    push %1 
    push %2                                             ; 8-Xpos, 8-yPos, 8-alpha, 4-numOfDestroyedTargets
    call calloc
    add esp,8
%endmacro

; macro that Initializing a paramenter in 1 drones' details
%macro init_drone 2
    mov [limit], dword %1                              
    call generate_random_number
    fstp qword [allocatedRand]
    fld qword [allocatedRand]
    fstp qword [eax+%2]
%endmacro    

; macro that prints the float 
%macro print_float 1
    fld dword [%1]
    sub esp, 8
    fstp qword[esp]
    push format_string_sscanf_floatPrint
    call printf
    add esp, 12
%endmacro

section	.rodata					                             
	format_string_sscanf_float: db "%f",10,0
    format_string_sscanf_floatPrint: db "%.2f",10,0
    
section .data
    maxSize: dd 65535                                       ; or to 65535
    d: dq 0
    N: dd 0
    t: dd 0
    k: dd 0
    seed: dd 0
    beta: dq 0
    xPos: dq 0
    yPos: dq 0 
    limit: dd 0 
    temp1: dd 0 
    temp2: dd 0
    temp3: dd 0 
    dronesArr: dd 0
    cors: dd 0
    corsLength: dd 0
    csp: dd 0                                               ; original stack top
    lastEsp:    dd 0                                        ; original stack top
    tempX: dq 0
    tempY: dq 0
    tempAlpha: dq 0
    tempScore: dq 0
    tempGamma: dq 0
    ySub: dq 0
    xSub: dq 0
    tempAbs: dq 0
    tempSquart: dq 0
    prev_co: dd 0                                           ; holdds the caller co routine id on cors
    currAlphaDeg: dq 0
    currAlphaRad: dq 0
    tempArg: dq 0
    isGameOver: dd 0
    randRes: dq 0
    allocatedRand: dq 0
    
section .bss     
   
section .text
    align 16

main:					
    mov ebx, dword[esp+8]                                  ; get first argv string into esi 
    mov eax, dword[ebx+4]                                  ; get the pointer to place 1 in argv
    lea ecx,[tempArg]
    push ecx
    runSscanfFloat
    getIntArgs N
    mov eax, dword[ebx+8]                                  ; get the pointer to place 2 in argv
    lea ecx,[tempArg]
    push ecx
    runSscanfFloat
    getIntArgs t
    mov eax, dword[ebx+12]                                 ; get the pointer to place 3 in argv
    lea ecx,[tempArg]
    push ecx
    runSscanfFloat
    getIntArgs k
    mov eax, dword[ebx+16]                                 ; get the pointer to place 4 in argv
    lea ecx,[beta]
    push ecx
    runSscanfFloat
    mov eax, dword[ebx+20]                                 ; get the pointer to place 5 in argv
    lea ecx,[d]
    push ecx
    runSscanfFloat
    mov eax, dword[ebx+24]                                 ; get the pointer to place 3 in argv
    lea ecx,[tempArg]
    push ecx
    runSscanfFloat
    getIntArgs seed
 
startFun                                                    ; of main
    call init_target
    call init_dronesArr
    call init_cors
    xor ebx,ebx
    call start_co                                         ; calling to start_co
    ;call resume
    call free_drones
    call free_cors
endFun                                                      ; of main

init_target:
    startFun
    mov [limit], dword 100                                  ; call random for x value in target
    call generate_random_number
    fstp qword [xPos]
    mov [limit], dword 100                                  ; call random for y value in target                     
    call generate_random_number
    fstp qword [yPos]
    endFun
    
init_dronesArr:
    startFun
    xor ecx,ecx
    mov ecx, dword [N]                                      ; ecx hold the number of drones
    mov [temp2], ecx                                        ; saves ecx into temp2
    runCalloc ecx, 4                                        ; Initializing the array of drones in size N*4 with N cells
    mov [dronesArr], dword eax                              ; set the first calloc to the dronesArr pointer
    mov ebx, [dronesArr]
    xor edx,edx
    mov [temp3] ,edx
    init_cell_drone:
        runCalloc 1, 28                                      ; 8-Xpos, 8-yPos, 8-alpha, 4-numOfDestroyedTargets
        mov edx, [temp3]                                     ; recover edx from temp3
        mov [ebx+edx*4], eax                                 ; saves the curr allocated pointer to the current cell 
        init_drone 100, 0                                    ; Initializing x position
        init_drone 100, 8                                    ; Initializing y position
        init_drone 360, 16                                   ; Initializing angle alpha
        mov [eax+24], dword 0                                ; Initializing numOfDestroyedTargets with 0
        mov ecx, [temp2]                                     ; recover ecx = N
        inc edx                                              ; edx++
        mov [temp3], edx                                     ; saves edx to temp3
        sub ecx, 1
        mov [temp2], ecx                                     ; saves ecx into temp2
        cmp ecx,0
        jne init_cell_drone
    endFun
    
init_cors:
    startFun
    xor edi,edi   
    xor ecx, ecx
    mov ecx, dword [N]
    add ecx, 3                                              ; adding 3 for - scheduler, printer, target
    mov [temp2], ecx                                        ; saves ecx into temp2
    mov [corsLength], ecx
    runCalloc ecx, 4
    mov ecx, [temp2]
    mov [cors], dword eax                                   ; set the first calloc to the dronesArr pointer
    mov ebx, [cors]
    xor edx,edx
    mov [temp3] ,edx
    init_cell_cor:
        runCalloc 1, 8                                       ; 4-functionPointer, 4-stackPointer(1024*16)
        mov ecx, [temp2]
        mov edx, [temp3]                                     ; recover edx from temp3
        mov [ebx+edx*4], eax                                 ; saves the curr allocated pointer to the current cell 
        init:
            cmp ecx, dword [corsLength]                      ; checks if we initialize the scheduler cell
            je scheduleCell
            mov esi,dword [corsLength]
            dec esi
            cmp ecx, esi                                      ; checks if we initialize the printer cell
            je printCell
            mov esi,dword [corsLength]
            dec esi
            dec esi
            cmp ecx, esi                                      ; checks if we initialize a drone cell
            je targetCell
            jmp droneCell                                     ; initialize the scheduler cell
        scheduleCell:
            mov dword [eax], scheduler                        ; 4 bytes of the struct are pointer to the 'run' function-scheduler
            mov [temp1],dword 0
		jmp allocateStack
        printCell:
            mov dword [eax], printer                           ; 4 bytes of the struct are pointer to the 'run' function-printer
            mov [temp1],dword 1          
            jmp allocateStack
        targetCell:
            mov dword [eax], createTarget                   ; 4 bytes of the struct are pointer to the 'run' function-createTarget
            mov [temp1],dword 2           
            mov dword edi,2
            jmp allocateStack
        droneCell:
            mov dword [eax], drone                          ; 4 bytes of the struct are pointer to the 'run' function-drone
            mov edi,[temp1]
            inc edi
            mov [temp1],dword edi
        allocateStack:
            mov edi,eax                                     ; now ecx pointes to the curr pointer to a con 
            runCalloc 1, 16384                              ; stack in size 1024*16
            add eax, dword 16384                            ; so the stack will be pointed to the end of it
            mov [edi+4], eax                                ; now in place ecx+4 there is a pointer to the stack
            call init_co
            mov edx, [temp3]                                ; recover edx from temp3    
            mov ecx, [temp2]                                ; recover ecx = N
            inc edx                                         ; edx++
            mov [temp3], edx                                ; saves edx to temp3
            sub ecx, 1
            mov [temp2], ecx                                ; saves ecx into temp2
            cmp ecx,0
            jne init_cell_cor
    endFun
    
init_co:                                                    ;precondition: ebx=co(i) index
    push ebx
    push edx
    push eax
    mov ebx, dword [temp1]
    mov edx, dword [cors]
    mov eax, dword [4*ebx+edx]	                             ; ebx = address of co struct
    mov [csp], esp		                                     ; save esp rig value
    lea esi,[eax+4]		                                     ; esp = address of coi stack
    mov esp,[esi]
    
    push dword [eax]			                             ; push initial return address
    pushfd			                                         ; push flags
    pushad			                                         ; push regs
    mov [eax+4],esp		                                     ; update stacki pointer
    mov esp,[csp]		                                     ; restore esp value
    pop eax
    pop edx
    pop ebx
    ret

generate_random_number:
    startFun                                               ; of random number
    pushad
    xor ecx,ecx
    mov ecx, 16
    calc_random:
        xor ebx, ebx
        mov ebx, dword [seed]
        mov eax, 1
        mov edi, 1
        and eax, ebx                                        ; check if the bit 16 is 'on'
        shr ebx, 2                                          ; moves to bit 14
        and edi, ebx                                        ; checks if bit 14 is 'on'
        xor eax, edi                                        ; xor bit 14 with bit 16
        mov edi, 1  
        shr  ebx, 1                                         ; moves to bit 13
        and edi, ebx                                        ; checks if bit 13 is 'on'
        xor eax, edi                                        ; xor bit 14 with bit 16 with bit 13
        mov edi, 1
        shr  ebx, 2                                         ; moves to bit 11
        and edi, ebx                                        ; checks if bit 11 is 'on'
        xor eax, edi                                        ; xor bit 14 with bit 16 with bit 13 with bit 11
        shl eax,  15
        shr dword[seed], 1
        xor dword [seed], eax
    loop calc_random, ecx
    calc_scale: 
        finit                                               ; Initializing x87
        cmp [limit], dword 120                              ; if it is the case of regular angle, then the calculation is +60
        jne reg_scale
        jmp special_scale
        reg_scale:
            fild dword [limit]
            fild dword [maxSize]                             ; limit/maxSize
            fdiv
            fild dword [seed]                                ; (limit/maxSize)*seed
            fmul
            jmp finRand
        special_scale:
            mov [temp1], dword 60
            fild dword [limit]
            fild dword [maxSize]                              ; limit/maxSize
            fdiv
            fild dword [seed]                                 ; (limit/maxSize)*seed
            fmul
            ;fstp qword [randRes]                             ; move ST(0) to randRes
            fild dword [temp1]                               
            fsub                                              ; ((limit/maxSize)*seed)-60
    finRand:
    popad
    endFun
   
convert_deg_to_rad:
    startFun
    finit 
    fld qword [currAlphaDeg]
    mov [temp1], dword 0
    mov [temp1], dword 180
    fild dword [temp1]
    fdiv
    fldpi
    fmul
    fstp qword [currAlphaRad]
    endFun
    
; specific to gamma
convert_rad_to_deg:
    startFun
    finit 
    fld qword [tempGamma]
    fldpi
    fdiv
    mov [temp1], dword 0
    mov [temp1], dword 180
    fild dword [temp1]
    fmul
    fstp qword [tempGamma]
    endFun
    
mayDestroy:                                                     ; precondition: ebx=co(i) index
    startFun            
    getDateDrone:
        mov edx, [dronesArr]
        mov eax, [edx+ebx*4]                                    ; the cuurent drone in the dronesArr
        fld qword [eax]                                         ; drone - x
        fstp qword [tempX]
        fld qword [eax+8]                                       ; drone - y 
        fstp qword [tempY]
        fld qword [eax+16]                                      ; deone - alpha
        fstp qword [tempAlpha]
        mov eax, dword 0                                        ; flag - cant destroy the target
    calcGamma:
        finit
        fld qword[yPos]                                         ; target - y2
        fld qword[tempY]                                        ; drone - y1
        fsub                                                    ; y2-y1
        fstp qword [ySub]                                       ; ySub = y2-y1
        fld qword[xPos]                                         ; target - x2
        fld qword[tempX]                                        ; drone - x1
        fsub                                                    ; x2-x1
        fstp qword [xSub]                                       ; xSub = x2-x1
        fld qword [ySub]                                       
        fld qword [xSub]                                        
        fpatan                                                  ; arctan2(y2-y1, x2-x1)
        fstp qword [tempGamma]
    convertGammaToDeg:
        call convert_rad_to_deg                                 ; now tempGamma is in degrees
    calcAbs:
        fld qword [tempAlpha]
        fld qword [tempGamma]
        fsub                                                    ; tempAlpha-tempGamma
        checkDifference:
            mov [temp1], dword 180
            fild dword [temp1]                                  ; enter pi
            fcomip                                              ; check if 180<tempAlpha-tempGamma,tempAlpha-tempGamma in stack
            jb checkHowGreater                                        
            jmp contAbs
        checkHowGreater:
            fld qword [tempAlpha]
            fld qword [tempGamma]
            fcomip                                              ; check if tempGamma<tempAlpha, tempAlpha in stack
            jb addTempGamma
            jmp addTempAlpha
            addTempGamma:
                fstp qword [tempArg]                            ; get tempAlpha out of stack,tempAlpha-tempGamma in stack
                fstp qword [tempArg]                            ; get tempAlpha-tempGamma out of stack, stack empty               
                fld qword [tempGamma]
                mov [temp1], dword 0
                mov [temp1], dword 360
                fild dword [temp1]                              ; enter 2*pi
                fadd                                            ; tempGamma + 2*pi
                fstp qword [tempGamma]
                fld qword [tempAlpha]
                fld qword [tempGamma]
                fsub 
                jmp contAbs
            addTempAlpha:
                fstp qword [tempArg]                            ; get tempAlpha out of stack,tempAlpha-tempGamma in stack
                fstp qword [tempArg]                            ; get tempAlpha-tempGamma out of stack, stack empty               
                fld qword [tempAlpha]
                mov [temp1], dword 0
                mov [temp1], dword 360
                fild dword [temp1]                              ; enter 2*pi
                fadd                                            ; tempAlpha + 2*pi
                fld qword [tempGamma]
                fsub 
        contAbs:
        fabs                                                    ; |(tempAlpha-tempGamma)|
        fstp qword [tempAbs]                                     
    check1:                                                     ; does (abs(alpha-gamma) < beta) ?
        fld dword [beta]
        fld qword [tempAbs]
        fcomip                                                  ; check if tempAbs<beta
        jb checkNext
        jmp endCheck
    checkNext:                                                   ; does sqrt((y2-y1)^2+(x2-x1)^2) < d ?
        calcSquart:
            fld qword [ySub]
            fld qword [ySub]
            fmul                                                 ; (y2-y1)^2
            fstp qword [ySub]                                    ; ySub = ySubPower
            fld qword [xSub]
            fld qword [xSub]
            fmul                                                 ; (x2-x1)^2
            fstp qword [xSub]                                    ; xSub = xSubPower
            fld qword [xSub]
            fld qword [ySub]
            fadd
            fsqrt
            fstp qword [tempSquart]
        check2:
            fld dword [d]
            fld qword [tempSquart]
            fcomip                                              ; check if tempSquart<d      
            jb updateFlag
            jmp endCheck
        updateFlag:
            mov eax, dword 1                                    ; flag - can destroy the target
    endCheck:
        endFun
    
free_drones:
    startFun
    xor ebx, ebx
    xor edx, edx
    xor eax, eax
    xor ecx, ecx
    xor esi, esi
    mov [temp1], dword 0
    mov ebx, [dronesArr]
    mov ecx, dword [N]
    mov [temp1], ecx                                            ; save ecx into temp1
    loop_free_drone:
        lea edx, [ebx+4*esi]                                    ; the current cell to be released in dronesArr      
        mov eax, [edx]
        push eax
        call free                                               ; call free to release memory
        add esp, 4
        inc esi
        mov ecx, [temp1]                                        ; recover ecx
        dec ecx
        mov [temp1], ecx
        cmp ecx,0
        jnz loop_free_drone
    push ebx
    call free
    add esp, 4
    endFun
    
free_cors:
    startFun
    xor ebx, ebx
    xor edx, edx
    xor eax, eax
    xor ecx, ecx
    xor esi, esi
    xor edi, edi
    mov [temp1], dword 0
    mov ebx, [cors]
    mov ecx, dword [N]
    add ecx, dword 3
    mov [temp1], ecx                                            ; save ecx into temp1
    loop_free_cor:
        lea edx, [ebx+4*esi]                                    ; the current cell to be released in dronesArr      
        mov edi, [edx]
        sub [edi+4], dword 16344
        lea edx, [edi+4]
        mov eax, [edx]                      
        push eax                                                ; free the 1024*16 stack
        call free                                               ; call free to release memory
        add esp, 4
        push edi                                                ; free the 8 bytes struct
        call free       
        add esp, 4
        inc esi
        mov ecx, [temp1]                                        ; recover ecx
        dec ecx
        mov [temp1], ecx
        cmp ecx,0
        jnz loop_free_cor 
    push ebx
    call free
    add esp, 4
    
    endFun

; ebx = co-routine index to start
start_co:
    pusha                                                       ; save all registers (restored in "end_co")
    mov [lastEsp], esp                                          ; save caller's stack top
    jmp resume.cont                                             ; perform state-restoring part of "resume"

; can be called or jumped to
end_co:
    mov esp, [lastEsp]                                          ; restore stack top of whoever called "start_co"
    popa                                                        ; restore all registers
    ret                                                         ; return to caller of "start_co"

; ebx = co-routine index to switch to
resume:                                                         ; "call resume" pushed return address
    pushf                                                       ; save flags to source co-routine stack
    pusha                                                       ; save all registers
    xchg edi, [prev_co]                                         ; ebx = current co-routine index
    mov edx, dword [cors]
    mov eax, [edx + edi*4]                                      ; update current co-routine's stack top
    lea esi,[eax+4]		                                        ; esp = address of coi stack
    mov [esi], esp
        
.cont:
    mov edx, dword [cors]
    mov eax, [edx + ebx*4]                                      ; get destination co-routine's stack top
    lea esi,[eax+4]		                                        ; esp = address of coi stack
    mov esp,[esi]
    mov [prev_co],ebx
    popa                                                        ; restore all registers
    popf                                                        ; restore flags
    ret                                                         ; jump to saved return address
