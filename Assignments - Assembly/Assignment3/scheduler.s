global scheduler,current_co                     ; make scheduler visible and current coroutine index
extern resume,end_co                            ; extern functions
extern N                                        ; num of drones
extern k                                        ; after k steps we call the printer co-r
extern isGameOver                               ; flag to know if there is a winner
extern current_co,prev_co

section .bss
align 16
    step12: resd 1                              ; holds the iteration num
    amountOfCors: resd 1                        ; amount of cors in the system
    it: resd 1
    
section .text
align 16

;first time in scheduler so init params
scheduler:
    xor esi, esi
    mov ecx, [k]                                ; ecx=k
    mov [step12],  ecx                          ; step=k
    mov ecx, [N]                                ; ecx = num of drones
    add ecx, 3                                  ; ecx = amount of cors (drones+target+printer+scheduler)
    mov dword [amountOfCors], ecx
    
;here starts everything after reset to the first drone
.scheduler_function:
    mov dword [prev_co],0
    mov dword ebx,3                        ;set the first cor as the first drone (the 1st drone is located at index 3 in cors array)
    
;perform switch to the routine    
.iterate:
    mov dword [prev_co],0
    call resume                                 ; switch to current drone cor

;check if the last drone destroyed the target T times and won so we need to end the scheduler routine
.check_win:
    cmp dword [isGameOver],1                    ; check if game isGameOver
    jne .printOnTime                            ; game is not over so continue iterate on drones
    call end_co
    
;check the iteration number and prints in case its required (i==k)
.printOnTime:
    mov esi, [it]
    inc esi
    mov [it], esi
    mov dword ecx, [step12]                     ; ecx = updated step count
    dec ecx                                     ; ecx--
    mov dword [step12],ecx                      ; step = step-1 : update step
    cmp dword ecx,0                             ; i==k?
    jg .continue_iterate                        ;if i!=k update i and continue iterating in loop
    ;switch to printer co-routine
    push ebx
    ;resume(printer) because i=k
    mov ebx,1
    mov dword [prev_co],0
    call resume
    mov dword [prev_co],0
    pop ebx                                     ; restore ebx
    ;after print has been made we updated the iteration couunter to k (or 'i=1')
    mov dword ecx, [k] 
    mov [step12],ecx
    
;switch to the next drone index
.continue_iterate:
    inc ebx                                     ; switch to the next drone index
    
;check if we need to reassign the drone to be the 1st one or iterate on this one
.cont:
    cmp dword ebx,[amountOfCors]                ; out of cors array bound (last time was iterating the last index drone)
    jl .iterate                                 ; the current index is a valid drone index
    ;else - need to reassign to the first drone index
    jmp .scheduler_function
    
    
    
    
    
