section .bss
		z: resd 1			;holds the result of the sum x+y
		isValid: resd 1		;holds the return value from the function c_checkValidity

section .data
		formatValid: db "z: %d" , 10, 0
		formatNotValid: db "illegal input" , 10, 0
section .text
		global assFunc		;the function is now seen from outside
		extern printf            	; 'extern' directive tells linker that printf(...) function is defined elsewhere
		
assFunc:
		push ebp			;backup ebp
		mov ebp,esp			;set the activation frame of the assFunc
		mov ecx,[ebp+8]		;get the second argument- x
		mov ebx,[ebp+12]	;get the first argument - y
		
		;call to the check validity function with x and y
		push ebx			;push y as argument
		push ecx			;push x as argument
		call c_checkValidity;call the validity function and push return address to stack and jump to function code
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;after that line 1/0 in eax as returned value;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;continue the perform of the function according to the returned value;;;;;;;;;;;
		mov [isValid],eax	;get returned value
		add esp,8			;free allocated space for arguments
		;check the returned value:
		cmp eax, byte 0
		JE printException
		;isValid=1 so calculates z=x+y
		add ebx,ecx
		mov [z],ebx	;z=x+y
		;print z in decimal base
		mov eax,[z]
		push eax
		push dword formatValid
		call printf
		add esp,8
		jmp backToCalled
	
		printException:
		push dword formatNotValid
		call printf
		add esp,4
						
		backToCalled:
					mov eax,0
					mov esp,ebp
					pop ebp
					ret
		
		
		
		
c_checkValidity:
				push ebp				;backup ebp
				mov ebp,esp				;set ebp to be where AF starts
				
				mov ecx,[ebp+8]			;get x into ebx
				mov ebx,[ebp+12]		;get y into ecx
				
				;perform the validity checks
				;check validity of x:			x<0?
				cmp ecx,0
				JL notValid
				;check validity of y:			y<=0?
				cmp ebx,0
				JLE notValid
				cmp ebx,0x8000			;y>2^15?
				JG notValid
				
				valid:					;this label put 1 in eax and jump over notvalid
						mov eax,1
						jmp end
				
				notValid:				;this label put 0 in eax and go to end
						mov eax,0
				
				end:					;this label returns to the previous received AF and ret
						
						mov esp,ebp
						pop ebp
						RET
		
		
		
		

		
		
		
