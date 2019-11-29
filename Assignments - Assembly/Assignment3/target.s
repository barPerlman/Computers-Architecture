;this is the tarhget co-routine implement

global createTarget
extern generate_random_number,resume
extern limit    ;holds 360 to generate angle or 100 for coordinate
extern xPos,yPos,randRes    ;coordinates of target location
extern current_co,prev_co


section .text

createTarget:
mov ebx, [prev_co]
;generate location
mov dword [limit], 0                        
mov dword [limit],100
;get a new x coordinate
call generate_random_number
fstp qword [xPos]                                       ; update new xPos for the target
;update y coordinate
call generate_random_number
fstp qword [yPos]                                       ; update new yPos for the target
;resume(scheduler)

xor ebx,ebx                                             ; next thread is the scheduler
mov [prev_co], dword 2                                  ; the current thread is the target (=2)
call resume
jmp createTarget

