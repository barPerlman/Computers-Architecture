section	.rodata					     ; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0		     ; format string

section .bss				       	     ; we define (global) uninitialized variables in .bss section
	an: resb 12				     ; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
    convertedNumber: resb 4 			     ; holds the converted number
    inputLength: resb 4				     ; holds the input length 
section .text
	global convertor
	extern printf
	
convertor:					     ; converts the input to decimal number
        push ebp
        mov ebp, esp	
        pushad			

        mov edx, dword [ebp+8]	                     ; get function argument (pointer to string)
        mov [convertedNumber], dword 0               ; initilize the convertedNumber with 32 ziros
        mov [inputLength], dword 0                   ; initilize the input length with 0
        mov eax, dword 0                             ; initilize the eax register for the div later 
        mov ecx,edx                                  ; ecx holds the string input

    updateConvertedNumber:                           ; converts the input string into a dword number (=convertedNumber)
        cmp byte [edx], 0x0A                         ; if the byte we compare is '\n'
        je checkTheInputLength                       ; we finished the conversion
        shl dword [convertedNumber], 1
        cmp byte [edx], '1'                          ; if the byte is 1, we want to include him in the convertedNumber
        je handleOne
        inc edx                                      ; moves to the next byte
        jmp updateConvertedNumber                    ; returns to the start of the loop 'updateConvertedNumber'

        handleOne:                                   ; add one to the convertedNumber
            add dword [convertedNumber], 1
            inc edx                                  ; moves to the next byte
            jmp updateConvertedNumber                ; returns to the start of the loop 'updateConvertedNumber'

    checkTheInputLength:                             ; check if the length is 32 , and if so check if it is negative
        cmp byte [ecx], 0x0A                         ; if the loop is over ('\n'=0x0A)
        je handleNegativeInput                       ; goes to 'handleNegativeInput'
        add byte [inputLength],1                     ; inputLength++
        inc ecx                                      ; moves to the next byte
        jmp checkTheInputLength                      ; returns to the start of the loop 'checkTheInputLength'

        handleNegativeInput:                         ; check if the size is 32 if the first char is negative  
            cmp dword [inputLength],0x20             ; if the length of the input is 32 bits (=20 in hex)
            je saveNegativeSign                      ; jump to saveNegativeSign
            mov edi, an                              ; edi and an points to the same place
            jmp convertToString                      ; jump to convertToString

        saveNegativeSign:                            ; if the number is negative then we eant to save it's sign
            cmp [convertedNumber], dword 0           ; if the first bit is 1 then it is a negative number
            jl updateANwithMinus                     ; jump to updateANwithMinus
            mov edi, an
            jmp convertToString			     ; jump to convertToString

        updateANwithMinus:			     ; updates an in case of a negative input
            mov edi, an				     ; an and edi holds the same pointers
            mov [edi], byte '-' 	  	     ; adds the - sign in the first bit in the result - an
            inc edi			 	     ; moves to the next byte
            neg dword [convertedNumber]	 	     ; doing neg fun to the number in order to show the negative convertion of the number
            jmp convertToString			     ; jump to convertToString

    convertToString:				     ; converts the calculated number to string
        mov eax, dword [convertedNumber] 	     ; later we will want to div eax with ebx (this is the build of div func)
        xor ecx, ecx 				     ; initilize ecx with 32 ziros
        mov ebx, dword 10 			     ; initilize the ebx register so we can split with it the convertedNumber (=eax)

        loopThatEntersEachNumberToTheStuck:	     ; pushes each byte to the stuck
            xor edx, edx 			     ; initilize edx with 32 ziros
            div ebx 			             ; divide eax by ebx and put the remainder in edx
            push edx 				     ; save the remainder in the stack
            inc ecx				     ; counter to register ecx
            cmp eax, 0				     ; if eax is 0 then ends the loop
            jnz loopThatEntersEachNumberToTheStuck   ; jump to loopThatEntersEachNumberToTheStuck

        loopThatConvertsEachNumberToChar:	     ; pops eack byte from the stuck and enters him 48 bits to compare him to char
            pop edx				     ; pops the remainder
            add edx,48				     ; adds to each bit 48 in order to convert him to char
            mov [edi], byte edx			     ; saves the char to register edi	
            inc edi				     ; moves to the next byte
            dec ecx				     ; reduce from the counter ecx
            cmp ecx, 0				     ; if ecx is 0 then ends the loop
            jnz loopThatConvertsEachNumberToChar     ; jump to loopThatConvertsEachNumberToChar
        mov [edi], byte 0x00			     ; adding null terminator

	push an					     ; call printf with 2 arguments -  
	push format_string			     ; pointer to str and pointer to format string
	call printf
    add esp, 8					     ; clean up stack after call
	
	popad			
	mov esp, ebp	
	pop ebp
	ret
