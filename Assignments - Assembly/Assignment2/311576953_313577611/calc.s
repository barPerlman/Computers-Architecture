;=================================Assignment2 CASPL=====================================;
;=================================Roy Levy 313577611====================================;
;=================================Rotem Hananya 311576953===============================;

;================================Main Functions Macros==================================;

    ; Type: macro
    ; Description: adds two list from the stack
    ; Arguments: None
    %macro addition  0  
        pushad
        clean_registers
        mov byte[carry],0
        mov byte[tmp_carry],0
        
        %%get_first_list:                               ; getting first list from the stack
            pop_link_from_stack
            mov edx, dword[last_pop]
            cmp edx,0
            je %%end_addition
            mov dword[last_pop_tmp], edx
            mov edi, dword[last_pop_tmp]                ; saving first list
        %%get_second_list:
            mov dword[last_pop], 0 
            pop_link_from_stack
            mov esi, dword[last_pop]                    ; saving second list

        %%check_second_null_addition:
            cmp esi,0
            je %%push_first_list_addition

        %%check_if_list_null_addtion:
            cmp esi,0
            je %%end_addition
            cmp edi, 0
            je %%end_addition

        %%start_addition:
            mov dword ecx, [edi+1]                      ; getting next for first list
            mov dword ebx, [esi+1]                      ; getting next for second list

            %%check_if_end_addition:
                cmp ecx, 0
                je %%end_addition_first_num
                cmp ebx, 0
                je %%end_addition_second_num

            %%add_with_carry:
                clean_reg edx
                clean_reg eax
                mov dl, byte[edi]
                mov al, byte[esi]
                add_nums_with_carry                              ; add data in the list with carry
                add_link dl                             ; creates a list with added datas

            %%set_next_addition:                         ; go to next elements in list
                mov edi, ecx
                mov esi, ebx
            jmp %%start_addition

        %%end_addition_first_num:                       ; indicates that first list 'next' is null
            %%check_second_list_empty:
                cmp ebx, 0
                je %%final_addition

            %%get_data_lists_first_num:                 ; gets data for two lists
                clean_reg eax
                clean_reg edx
                mov dl, byte[esi]
                mov al, byte[edi]

            %%add_nums_first_num:
                mov byte[edi], 0                        ; sets first list to null
                add_nums_with_carry                     ; add with carry datas
                add_link dl                             ; add added link
            %%set_next_second_num:
                mov esi, ebx
                jmp %%start_addition

        %%end_addition_second_num:
            %%check_first_list_empty:
                cmp ecx, 0
                je %%final_addition

            %%get_data_lists_second_num:
                clean_reg eax
                clean_reg edx
                mov dl, byte [edi]
                mov al, byte[esi]
            
            %%add_nums_second_num:
                mov byte[esi] , 0
                add_nums_with_carry
                add_link dl

            %%set_next_first_num:
                mov edi, ecx
                jmp %%start_addition
            
        %%final_addition:
            clean_reg edx
            clean_reg eax

            %%get_data_final_addition:
                mov dl, byte[edi]
                mov al, byte[esi]
            %%add_data_final_addition:
                add_nums_with_carry
        
            add_link dl
            clean_reg edx

            %%add_carry_final:
                mov dl, byte[carry]
                cmp dl, 0                               ; if false link with carry '1' need to be added
                je %%pre_exit_addition
                %%is_carry_addition:
                    add_link dl
                jmp %%pre_exit_addition
        
        %%push_first_list_addition:
            push_link_to_stack last_pop_tmp
            jmp %%end_addition
            
        %%pre_exit_addition:
            %%free_memory_addition:                     ; frees allocated memory of temp vars
                remove_and_free_list last_pop
                remove_and_free_list last_pop_tmp

            %%prepare_and_push_added_list:
                mov ebx, dword[first_link]              ; get the manipulated list
                mov dword[addition_tmp], ebx            ; saves the list
                mov dword[first_link], 0                ; points first_link to null  
                list_reverse addition_tmp               ; reverse the list
                remove_and_free_list addition_tmp       ; frees temp var
                push_link_to_stack first_link           ; push new list

        %%check_debug_addition:
            cmp byte [debug_mode] , 1
            je debug_main

        %%end_addition:
            popad
    %endmacro

    ; Type: macro
    ; Description: pops the top list in the stack and prints it
    ; Arguments:
    ; 1 - pointer to a list to print
    %macro pop_and_print 1
        pushad
        clean_registers
        mov byte [printed_first_link_flag], 0
        mov esi, dword[%1]                              ; get the content of the first link
        cmp esi, 0                                      ; if list is null then go to end
        je %%end_pop_and_print

        %%start_print:
            mov dword ebx, [esi+1]                      ; get 'next' of current link
            mov dword[print_var_temp], ebx              ; saving 'next' of current link
            cmp ebx, 0                                  ; if null, print last link
            je %%print_last_link
            clean_reg edx
            mov dl, byte[esi]                           ; get 'data' to print of current link
            cmp dl , 0
            jne %%print_first_link                      ; if not equal first link need to be printed
            cmp byte [printed_first_link_flag], 0
            je %%start_print_next

        %%print_hex_normal:                             ; printing link in 02X format
            pushad
            push edx
            push hex_format_2
            call printf
            popad

        %%start_print_next:
            %%get_next_link_pop_and_print_1:
                mov esi, dword [print_var_temp]             ; register now holds 'next' of prev link
                jmp %%start_print

        %%push_hex_1:                                   ; pushing hex "%X" format
            mov byte [printed_first_link_flag], 1       ; say we printed first_link
            push hex_format_1
            jmp %%call_printf_print

        %%print_first_link:
            cmp byte [printed_first_link_flag], 1       ; if true, first link been printed
            je %%print_hex_normal
            pushad
            push edx
            push hex_format_1
            call printf
            popad

        %%get_next_link_pop_and_print_2:
            mov byte [printed_first_link_flag], 1       ; saying we printed first_link
            mov esi, dword[print_var_temp]              ; register now hold 'next' of prev link
            jmp %%start_print

        %%print_last_link:
            clean_reg edx
            mov dl, byte[esi]                           ; get data of last link
            pushad
            push edx
            cmp byte[printed_first_link_flag],0         ; if true then first link is last also
            je %%push_hex_1
            push hex_format_2
            %%call_printf_print:
                call printf
                popad
                jmp %%end_pop_and_print

        %%end_pop_and_print:
            popad
    %endmacro

    ; Type: macro
    ; Description: duplicates the top element in the stack
    ; Arguments:
    ; 1 - pointer to top list on the stack
    %macro duplicate 1
        pushad
        clean_registers

        %%get_first_link_duplicate:
            mov eax, [%1]                           ; gets first link
            cmp eax, 0                              ; if null, list is empty then end
            je %%end_duplicate

        %%start_duplicate:
            mov dword edx, [eax+1]                  ; get 'next' of current link
            cmp edx, 0                              ; if null, then last link
            je %%final_duplicate

            mov cl, byte[eax]                       ; gets 'data' of current link
            add_link cl                             ; add 'data' to a new list
            mov eax,edx                             ; get next link
            jmp %%start_duplicate

        %%final_duplicate:
            mov cl, byte[eax]                       ; gets 'data' of last link
            add_link cl
            
        %%end_duplicate: 
            popad
    %endmacro

     ; Type: macro
     ; Description: performs list1*2^list2, where the two lists poped from the stack
     ; Arguments: None
    %macro power 0
        pushad
        clean_registers
        

        %%get_lists_power:
            pop_link_from_stack                         ; get first list from stack
            mov ebx, dword[last_pop]                    ; saves the list
            cmp ebx,0
            je %%end_power
            mov dword[last_pop_tmp], ebx                ; saves the list in temp var
            pop_link_from_stack                         ; get second list from stack
            mov edi, dword[last_pop]                    ; saves second list
            cmp edi,0
            je %%error_second_null_power

        %%check_validity_power:
            mov ecx, dword[edi+1]                       ; get 'next' for Y list
            cmp ecx, 0                                  ; if not null than smallest number is 256, throws error
            jne %%error_greater_200
            mov ecx, 0
            mov cl, byte[edi]
            mov ebx, 200
            cmp ecx, ebx
            jg %%error_greater_200                      ; if number greater than 200 throws error
            
        get_Y_power:
            mov ebx, 0
            mov cl, byte[edi]                           ; get data of Y list
            mov byte[counter], 0                        ; zeros counter
            mov byte[counter], cl                       ; moving Y data to counter

        %%start_power:
            %%check_end:
                cmp byte[counter], 0
                je %%pre_exit_power
        
            mov esi, dword[last_pop_tmp]
            mov byte[is_carry_power], 0

        %%start_mul_by_2:
            cmp esi,0                                   ; if true than we performed a mul by 2
            je %%endLoop
            mov dl, byte[esi]                           ; gets data of current link

        %%check_carry_start_mul:
            cmp byte[is_carry_power], 1 
            je %%add_carry_power

            shl dl, 1                                   ; mul data by 2
            mov ecx, 0
            adc ecx, 0                                  ; get carry after prev mul
            mov dword[is_carry_power], ecx              ; save carry
            mov byte[esi], dl                           ; update data
            mov dword[temp_list_power], esi
            mov esi, [esi+1]                            ; get next data
        jmp %%start_mul_by_2

        %%add_carry_power:
            shl dl, 1                                   ; mul data by 2
            mov ecx, 0
            adc ecx, 0                                  ; get carry for
            mov dword[is_carry_power], ecx
            add dl, 1                                   ; add prev carry
            mov byte [esi], dl 
            mov dword[temp_list_power], esi
            mov esi, [esi+1]                            ; get next link
            jmp %%start_mul_by_2

        %%endLoop:
            dec_counter ebx                             ; done mul by 2 ,now counter-1 remaining
            %%check_carry_end_mul_by_2:
                cmp byte[is_carry_power], 0
                je %%start_power

            %%carry_end_mul_by_2:
                mov dword[first_link], 0                ; set first_link pointer to null
                mov dl, 1                               ; init dl with 1
                add_link dl                             ; add link to head of list with data: 1
                mov ecx, dword[temp_list_power]         ; take prev list
                mov esi, dword[first_link]              ; mov first_link content to esi
                mov [ecx+1], esi                        ; set 'next' of final link in list to be 1
                jmp %%start_power

        %%error_greater_200:
            write 1, error_power,13                     ; prints error message
            write_new_line 1                            ; print new line
            push_link_to_stack last_pop                 ; leave the stack as is
            jmp %%pre_exit_power

            %%error_second_null_power:
                push_link_to_stack last_pop_tmp                 ; leave the stack as is
                jmp %%end_power 

        %%pre_exit_power:
            push_link_to_stack last_pop_tmp
	    remove_and_free_list last_pop
        %%end_power:
            popad
    %endmacro

        ; Type: macro
    ; Description: performed list1*2^(-list2) on two list in the stack
    ; Arguments: None
    %macro neg_power 0
        pushad
        clean_registers
        

        %%get_first_list_neg_power:
            pop_link_from_stack
            mov ecx, dword[last_pop]
            cmp ecx,0
            je %%end_neg_power
            mov dword[last_pop_tmp], ecx
	    mov dword[freeList] , ecx

        %%get_second_list_neg_power:
            pop_link_from_stack
            mov esi, dword[last_pop]
            cmp esi,0
            je %%error_second_null_neg_power

        %%check_Y_validity_neg_power:
            mov ebx, dword[esi+1]
            cmp ebx, 0
            jne %%error_neg_power                                       ; if true than min number is 256, error
            mov ebx, 0
            mov bl, byte[esi]
            mov ecx, 200
            cmp ebx, ecx                                                ; if true than number greater than 200
            jg %%error_neg_power

        %%get_Y_value_neg_power:
            mov ecx, 0
            mov cl, byte[esi]
            mov byte[counter], 0
            mov byte[counter], cl
        
        %%get_first_list_reversed_neg_power:
            list_reverse last_pop_tmp
            mov ebx, dword[first_link]
            mov dword[last_pop_tmp], ebx

        %%start_neg_power:
            cmp byte[counter], 0
            je %%pre_exit_neg_power

            mov edi, dword[last_pop_tmp]
            mov byte[is_carry_power], 0

            %%neg_power_loop:
                cmp edi, 0
                je %%end_calc_neg
                mov dl, byte[edi]
                cmp byte[is_carry_power], 1
                je %%add_neg_power

                shr dl, 1
                mov ebx, 0
                adc ebx, 0
                mov dword[is_carry_power], ebx
                mov byte[edi], dl
                mov dword[temp_list_power], edi
                mov edi, [edi+1]
                jmp %%neg_power_loop

            %%add_neg_power:
                shr dl, 1
                mov ebx, 0
                adc ebx, 0
                mov dword[is_carry_power], ebx
                add dl, 128
                mov byte[edi], dl
                mov dword[temp_list_power], edi                     ; get current link
                mov edi, [edi+1]                                    ; get next link
                jmp %%neg_power_loop

        %%end_calc_neg:
            %%dec_counter_neg_power:
                mov ecx, dword[counter]                             ; get prev counter
                dec ecx                                             ; dec counter
                mov dword[counter], ecx                             ; save new counter
            
            %%check_if_end_iteration_neg_power:
                cmp byte[last_pop_tmp], 0
                jne %%start_neg_power

            mov ebx, dword[last_pop_tmp]
            mov eax, ebx                                            ; saves var to free
            mov ebx, [ebx+1]                                        ; get next_link
            mov dword[last_pop_tmp], ebx                            ; set next in last_pop_tmp

            %%free_tmp_var_neg_power:                               ; free prev temp list
                pushad
                push eax
                call free
                add esp, 4

            %%return_to_main_loop_neg_power:
                popad
                jmp %%start_neg_power
                
        %%error_neg_power:
            write 1, error_power,13
            write_new_line 1
            push_link_to_stack last_pop
            jmp %%pre_exit_neg_power

            %%error_second_null_neg_power:
                push_link_to_stack last_pop_tmp
                jmp %%end_neg_power

        %%pre_exit_neg_power:
            mov dword[first_link], 0
            list_reverse last_pop_tmp                               ; revese the calculated list
            push_link_to_stack first_link                           ; push the list to the stack
            remove_and_free_list last_pop
	    remove_and_free_list freeList        
	%%end_neg_power:
            popad
    %endmacro

    ; Type: macro
    ; Description: gets a list and prints number of ones of the binary represantation of the numbers in the list
    ; Arguments:
    ; 1 - pointer to a list
    %macro num_of_ones 1 
        pushad
        clean_registers
        mov edi, dword [%1]                         ; gets first link
        cmp edi,0                                   ; if list is empty go to end
        je %%end_num_of_ones
        clean_reg ecx                               ; will hold num of ones 
        %%start_counting_ones:

            %%get_next_link_number_of_ones:
                mov edx, [edi+1]                    ; get next link             
                cmp edx, 0                          ; if true last link need be hancled
                je %%final_num_of_ones

            %%move_byte_num_of_ones:
                mov al ,byte [edi]
                mov bl ,al

                %%inner_byte_count:
                    cmp al , 0
                    je %%next_link_count_ones
                    and bl , 1
                    cmp bl , 1                      ; if true 1 need to be added
                    je  %%add_one
                    shr al , 1                      ; shifting right to get the next bit of the number 
                    mov bl , al
                    jmp %%inner_byte_count
                    
                    %%add_one:
                        inc ecx                     ; inc num of ones
                        shr al, 1
                        mov bl, al
                        jmp %%inner_byte_count

            %%next_link_count_ones:
                    mov edi, edx                    ; get next link
                    jmp %%start_counting_ones
                        
            %%final_num_of_ones:
                mov al, byte[edi]                   ; get data of last link
                mov bl, al                          ; copy data
                %%inner_byte_count_final:
                   cmp al, 0
                    je %%end_num_of_ones
                    and bl, 1
                    cmp bl, 1
                    je  %%add_one_final
                    shr al, 1 
                    mov bl, al
                    jmp %%inner_byte_count_final

                    %%add_one_final:
                        inc ecx
                        shr al ,1
                        mov bl , al
                        jmp %%inner_byte_count_final
                           
        %%end_num_of_ones:
            mov dword [first_link], 0           ; points to null
            cmp ecx,255
            jle %%dont_add_one_num_of_ones
            mov byte[add_256_no], cl
            mov ecx,1
            add_link cl
            mov cl,byte[add_256_no]
            %%dont_add_one_num_of_ones:
                add_link cl
                popad
            %%push_list_num_of_ones:
                push_link_to_stack first_link       ; pushing the list
            popad

        %%check_debug_num_of_ones:                  ; check if debug mode activated
            cmp byte[debug_mode], 1
            je debug_main
    %endmacro

    ; Type: macro
    ; Description: exits the program via system call
    ; Arguments: 1 - quit status 
    %macro quit 1
        sys_call 1,%1,0,0
    %endmacro
;============================End Main Functions Macros==================================;
;==============================AUX Functions Macros=====================================;
    ; Type: macro
    ; Description: pops last element from the stack, saving it in last_pop
    ; Arguments: None
    %macro pop_link_from_stack 0
        pushad
        mov dword[last_pop],0
        cmp dword[stack_count], 0
        je %%stack_underflow_error                  ; if num of element is zero throws error
        
        %%start_pop_from_stack:
            clean_registers                         ; clean registers for future use
            dec byte[stack_count]                   ; dec number of elements in the stack
            mov eax, dword[stack_count]
            mov ebx, dword[stack + 4*eax]
            mov dword [stack + 4*eax], 0            ; pointing the poped element pointer to null
            mov dword[last_pop], ebx                ; save poped element
            jmp %%end_pop_link_from_stack

        %%stack_underflow_error:                    ; prints error message
            write 1,error_insufficient,49
            write_new_line 1

        ;%%return_to_sender_loop_pop_link:           ; returns to main start_remove if popping failed
            ;popad
            ;call myCalc

        %%end_pop_link_from_stack:
            popad
    %endmacro

    ; Type: macro
    ; Description: pushes a list to the stack, prints error if failed
    ; Arguments:
    ; 1 - pointer to a list
    %macro push_link_to_stack 1
        pushad
        cmp dword [stack_count], 5
        jge %%stack_overflow_error                  ; if num of elements in the stack is >5 throws error
        
        %%start_push_to_stack:
            clean_registers
            mov  eax, dword [%1]                    ; saving the content of the head of the list
            mov  ebx, dword [stack_count]           ; saving amount of elements in the stack
            mov dword [stack + 4*ebx], eax          ; pushing the list onto the stack
            inc byte [stack_count]                  ; inc number of elements
            jmp %%end_push_link_to_stack

        %%stack_overflow_error:                     ; printing stack overflow error
            write 1, error_stack_overflow,30
            write_new_line 1

        %%end_push_link_to_stack:
            popad 
    %endmacro

    ; Type: macro
    ; Description: allocates memory for link of size 5
    ; Arguments: None
    %macro create_link 0
        mov ebx , 5
        push ebx
        call malloc
        pop ebx
    %endmacro

    ; Type: macro
    ; Description: adds a link to head of a list given as argument, create a new list if null
    ; Arguments:
    ; 1 - pointer that points to number of which a link should be created
    %macro add_link 1
        pushad
        mov byte [num1], %1                         ; gets the data of the link to add      
	create_link                                 ; creates a link with given data
	;clean_reg ecx
	;mov ecx , dword [stack_count]
	;jge %%end_add_link          
	clean_reg ecx                               ; clean ecx for future use
        mov cl, byte [num1]                         ; saving new link data
        mov byte [eax], cl
        cmp dword [first_link] ,0                   ; check if list is empty
        je %%is_first_link

        %%not_empty_list:
            mov dword edx, [first_link]             ; getting current head of the list
            mov dword[eax+1] , edx                  ; pointer 'next' of new link to old list
            mov dword[first_link] , eax             ; newly added link is now head of the list
        jmp %%end_add_link

        %%is_first_link:
            mov dword [first_link], eax             ; newly added link is now head of the list
            mov dword [eax+1], 0                    ; link 'next' is null
        %%end_add_link:
            popad    
    %endmacro

    ; Type: macro
    ; Description: removes a list from stack and free it's memory
    ; Arguments:
    ; 1 - pointer to the list
    %macro remove_and_free_list 1
        pushad
        %%get_data_remove_and_free_list:
            mov dword ebx, [%1]                     ; gets first_link
            mov dword esi, ebx                      ; saves first link
        %%start_remove:

            %%get_next_link_remove_and_free_list:
                mov dword edi, [esi+1]              ; get 'next' of current link
                cmp edi, 0                          ; if null remove and free last link
                je %%final_remove_and_free_list

            %%free_link_remove_and_free_list:
                push esi
                call free
                pop esi

            %%set_next_remove_and_free_list:
                mov esi,edi                         ; sets esi to next
                jmp %%start_remove

        %%final_remove_and_free_list:
            push esi
            call free

        %%end_remove_and_free_list:
            popad
    %endmacro

    ; Type: macro
    ; Description: reverse a list
    ; Arguments:
    ; 1 - pointer to a list
    %macro list_reverse 1
        pushad
        clean_registers

        %%get_first_link_list_reverse:
            mov eax, dword[%1]                      ; gets first link of list
            cmp eax, 0                              ; if true, list is null ,go to end
            je %%end_list_reverse
        
        %%start_reverse:
            mov dword ebx, [eax+1]                  ; gets 'next' of current link
            cmp ebx, 0                              ; if true, last link
            je %%final_list_reverse
            mov dl, byte[eax]                       ; gets 'data' of current link
            add_link dl                             ; creates a new list with data

        %%get_next_link_list_reverse:
            mov eax, ebx                            ; get next link
            jmp %%start_reverse

        %%final_list_reverse:
            mov dl, byte[eax]
            add_link dl

        %%end_list_reverse:
            popad
    %endmacro

    ; Type: macro
    ; Description: get register and decrement counter var
    ; Arguments:
    ; 1 - register
    %macro dec_counter 1
        mov %1, dword[counter]
        dec %1
        mov dword[counter], %1
    %endmacro

    ; Type: macro
    ; Description: add two numbers with carry
    ; Arguments: None
    %macro add_nums_with_carry 0
        add edx,eax
        clean_reg eax
        mov al,byte[carry]
        add edx,eax
        mov byte[carry],dh
        mov dh,0
        mov ah,0
    %endmacro

    ; Type: macro
    ; Description: gets two numbers add then by hex addition
    ; Arguments:
    ; 1 - first num
    ; 2 - second num
    %macro perform_hex_addition 2
        shl %2, 4                                       ; 2^4 to second num
        add %1, %2
    %endmacro

    ; Type: macro
    ; Description: gets a char from buffer, inc buffer index to next char
    ; Arguments:
    ; 1 - buffer to save the char read
    %macro get_char 1
        mov %1 ,  [buffer+edx]
        inc edx
    %endmacro

    ; Type: macro
    ; Description: converts char to number or letter for hex handling
    ; Arguments:
    ; 1 - char to convert 
    %macro convert_char 1
        cmp  %1 , 'A'
        jae %%is_letter                             ; if above or equal than first arg is a letter

        %%is_number:
            sub %1, '0'
            jmp %%end_convert_char

        %%is_letter:
            sub %1, 'A'
            add %1 , 10
        %%end_convert_char:
    %endmacro

    ; Type: macro
    ; Description: cleans a register specified
    ; Arguments: 
    ; 1 - name of register
    %macro clean_reg 1
        xor %1,%1
    %endmacro

    ; Type: macro
    ; Description: cleans registers eax,ebx,ecx,edx
    ; Arguments: None
    %macro clean_registers 0
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
        xor edx,edx
    %endmacro

    ; Type: macro
    ; Description: writes a new line to a file descriptor
    ; Arguments:
    ; 1 - file descriptor
    %macro write_new_line 1
        pushad
        mov byte [new_line] , 10
        sys_call 4,%1,new_line,1
        popad
    %endmacro

    ; Type: macro
    ; Description: performs a system call
    ; Arguments: 1-4 applicable arguments for each system call   
    %macro sys_call 4
        mov eax, %1        
        mov ebx, %2
        mov ecx, %3
        mov edx, %4
        int 0x80
    %endmacro

    ; Type: macro
    ; Description: reads from stdin input to a buffer
    ; Arguments:
    ; 1 - buffer pointer
    ; 2 - buffer size
    %macro read_from_stdin 2
        sys_call 3,0,%1,%2
    %endmacro

    ; Type: macro
    ; Description: writes to a buffer number of bytes specified,starts from a given file descriptor
    ; Arguments:
    ; 1 - file descriptor
    ; 2 - buffer to write into
    ; 3 - number of bytes to write
    %macro write 3
        pushad
        sys_call 4,%1,%2,%3
        popad
    %endmacro

    ; Type: macro
    ; Description: pops the top list in the stack and prints it
    ; Arguments:
    ; 1 - pointer to a list to print
    %macro pop_and_print_debug 1
        pushad
        clean_registers
        mov byte [printed_first_link_flag], 0
        mov edi, dword[%1]                              ; get the content of the first link
        cmp edi, 0                                      ; if list is null then go to end
        je %%end_pop_and_print_debug

        %%start_print_debug:
            mov dword ecx, [edi+1]                      ; get 'next' of current link
            mov dword[print_var_temp], ecx              ; saving 'next' of current link
            cmp ecx, 0                                  ; if null, print last link
            je %%print_last_link_debug
            clean_reg edx
            mov dl, byte[edi]                           ; get 'data' to print of current link
            cmp dl , 0
            jne %%print_first_link_debug                ; if not equal first link need to be printed
            cmp byte [printed_first_link_flag], 0
            je %%start_print_next_debug

        %%print_hex_normal_debug:                             ; printing link in 02X format
            pushad
            push edx
            push hex_format_2
            call printf
            popad

        %%start_print_next_debug:
            %%get_next_link_pop_and_print_1_debug:
                mov edi, dword [print_var_temp]             ; register now holds 'next' of prev link
                jmp %%start_print_debug

        %%push_hex_1_debug:                                   ; pushing hex "%X" format
            mov byte [printed_first_link_flag], 1       ; say we printed first_link
            push hex_format_1
            jmp %%call_printf_print_debug

        %%print_first_link_debug:
            cmp byte [printed_first_link_flag], 1       ; if true, first link been printed
            je %%print_hex_normal_debug
            pushad
            push edx
            push hex_format_1
            call printf
            popad

        %%get_next_link_pop_and_print_2_debug:
            mov byte [printed_first_link_flag], 1       ; saying we printed first_link
            mov edi, dword[print_var_temp]              ; register now hold 'next' of prev link
            jmp %%start_print_debug

        %%print_last_link_debug:
            clean_reg edx
            mov dl, byte[edi]                           ; get data of last link
            pushad
            push edx
            cmp byte[printed_first_link_flag],0         ; if true then first link is last also
            je %%push_hex_1_debug
            push hex_format_2
            %%call_printf_print_debug:
                call printf
                popad
                jmp %%end_pop_and_print_debug

        %%end_pop_and_print_debug:
            popad
    %endmacro

    ; Type: macro
    ; Description: prints top list on the stack if debug mode is activated
    ; Arguments: None 
    %macro debug 0
        mov dword [first_link], 0                       ; set first link to null
        %%get_last_list_debug:
            mov dword ecx,[stack_count]                 ; get num of elements
            dec ecx
            mov dword ebx, [stack + 4*ecx]              ; points to last element
            mov dword [debug_list_ptr],ebx              ; saves last element
        list_reverse debug_list_ptr                     ; reverse list to print
        pop_and_print first_link                  ; prints top list
        %%print_new_line_debug:
            pushad
            mov edx , 0
            push edx
            call fflush
            popad
            write_new_line 2
        %%free_list_debug:
            mov dword [debug_list_ptr],0                ; points the temp var to null
            remove_and_free_list first_link             ; frees the new reversed list
    %endmacro
;==========================End AUX Functions Macros=====================================;
;==============================Main Logic Functions ====================================;
section .data
        stack_count: dd 0
        operation_counter: dd 0
        main_list_len: dd 0
	freeList: dd 0

section .bss
        stack: resb 20  ;the stack that will keep the numbers
        buffer: resb 82

        first_link: resb 4
        last_pop: resb 4
        debug_list_ptr: resb 4
        print_var_temp: resb 4
        addition_tmp: resb 4
        last_pop_tmp: resb 4
        temp_list_power: resb 4

        new_line: resb 1
        num1: resb 1

        carry: resb 1
        tmp_carry: resb 1
        counter: resb 1
        add_256_no: resb 1

        printed_first_link_flag: resb 1
        debug_mode: resb 1
        even_odd_flag: resb 1
        is_carry_power: resb 1
        byte_not_zero_flag: resb 1


section .rodata
        calc: dq "calc: "
        hex_format_1: db "%X" ,0
        hex_format_2: db "%02X" ,0
        error_stack_overflow: dq  "Error: Operand Stack Overflow" ,0            
        error_power: dq "wrong Y value", 0
        error_insufficient: dq  "Error: Insufficient Number of Arguments on Stack", 0
        format_decimal: db "%d" ,10, 0     
        debug_lbl: dq "debug_lbl: "
 
section .text
    align 16
        global main
        extern printf
        extern fprintf
        extern fflush
        extern malloc
        extern free
main: 
        push ebp
        mov ebp, esp    
        pushad

        mov byte [debug_mode],0
        cmp dword[ebp+8],1
        je call_myCalc
        mov byte[debug_mode],1
    
    call_myCalc:
        call myCalc
        
    myCalc: 
       
        write 1,calc,6
        read_from_stdin buffer ,82
            
        mov al , byte [buffer]
        cmp al , 'q'
        je quit_main
        cmp al,  '+'
        je addition_main
        cmp al,  'p'
        je pop_and_print_main
        cmp al , 'd'
        je dupllicate_main
        cmp al,  '^'
        je power_main
        cmp al, 'v'
        je neg_power_main
        cmp al , 'n'
        je num_of_ones_main
        
    build_list_from_input_main:

        clean_registers
        mov dword[main_list_len], 0
        mov byte[even_odd_flag], 0

        get_main_list_len:   
            mov al, byte [buffer+edx]                               ; get byte at buffer+edx
            cmp al, 10                                              ; check if new line
            je even_or_odd                                          ; if true jump to check even odd
            cmp al, 0                                               ; check if null
            je even_or_odd                                          ; if true jump to check even odd
            cmp al, '0'
            je get_next_byte
            mov byte [byte_not_zero_flag], 1                        ; setting flag to inc len
            inc byte [main_list_len]                                ; inc len
            inc edx                                                 ; inc buffer index
            jmp get_main_list_len

        get_next_byte:
            je get_next_link_get_list_len
            inc edx
            jmp get_main_list_len
            
        get_next_link_get_list_len:
            inc byte[main_list_len]                                 ; inc len
            inc edx                                                 ; inc buffer index
            jmp get_main_list_len
            
        even_or_odd:
            clean_reg eax
            mov ecx, 2
            mov eax, dword[main_list_len]
            clean_reg edx
            div ecx                                                 ; div main_list_len/2
            cmp edx, 0                                              ; if edx(remainder) is 0 than even
            je even
            mov byte[even_odd_flag], 1                              ; else odd - set flag
            jmp build_actual_list
            
        even: 
            mov byte[even_odd_flag], 0
            jmp build_actual_list
        ret
        
        
        build_actual_list:
            mov dword[first_link], 0                                ; first link is null
            pushad
            clean_registers
            cmp byte[even_odd_flag], 1                              ; check to build first link with odd number
            je build_odd_first_link

            start_build_ac_list:

                get_char bl                                         ; getting first char
                cmp bl, 10                                          ; if true than finish
                je end_build_ac_list
                cmp bl, 0                                           ; if true than finish
                je end_build_ac_list

                get_char cl                                         ; getting second char
                cmp cl, 10                                          ; if true than finish
                je end_build_ac_list
                cmp cl, 0                                           ; if true than finish
                je end_build_ac_list

                convert_char bl                                     ; converting first char
                convert_char cl                                     ; convert second char
                perform_hex_addition cl, bl                         ; adding two chars by hex addition

                add_link cl                                         ; adding link to list
                jmp start_build_ac_list

            build_odd_first_link:
                get_char bl                                         ; getting first char
                convert_char bl                                     ; converting first char
                mov dword ecx, '0'                                  ; setting second char to be '0'
                convert_char cl                                     ; convert to 0
                perform_hex_addition bl, cl                         ; adding two char by hex addition

                add_link bl                                         ; add odd link
                jmp start_build_ac_list
                
            end_build_ac_list:
                popad
                
            push_link_to_stack first_link                           ; pushing the newly created list
            cmp byte [debug_mode], 1
            je debug_main
            call myCalc

        
    main_functions_main:

        addition_main:
            mov dword [first_link], 0
            addition
            inc byte[operation_counter]
            call myCalc
            
        pop_and_print_main:
            mov dword [first_link], 0                           ; init pointer first_link
            mov dword [last_pop], 0                             ; init pointer last_pop

            pop_link_from_stack                                 ; pop top list
            mov ebx, dword[last_pop]
            cmp ebx,0
            je end_pop_and_print_main
            list_reverse last_pop                               ; reverse the list for printing
            pop_and_print first_link                            ; pop and print the reversed list

            pushad
            mov edx, 0
            push edx
            call fflush                                         ; just to make sure the list was printed before new line
            popad
            write_new_line 1                                    ; print new line

            remove_and_free_list last_pop                       ; free last_pop
            remove_and_free_list first_link                     ; free first_link
            end_pop_and_print_main:
            inc byte[operation_counter]                         ; operation_counter++
            call myCalc
            
        dupllicate_main:
            clean_registers
            mov dword [first_link], 0
            pop_link_from_stack                                 ; popping top element from the stack
            mov ebx,dword[last_pop]
            cmp ebx,0
            je end_duplicate_main
            push_link_to_stack last_pop                         ; push poped element to the stack
            duplicate last_pop                                  ; duplicate poped element

            mov edx, dword [first_link]
            mov dword[last_pop] , edx
            mov dword[first_link] , 0
            list_reverse last_pop
            remove_and_free_list last_pop                       ; remove temp var
            push_link_to_stack first_link                       ; push the duplicated list

        end_duplicate_main:
            inc byte[operation_counter]                         ; operation_counter++
            cmp byte [debug_mode] , 1                           ; check if debug
            je debug_main
            call myCalc

        power_main:

            mov dword[first_link], 0
            mov dword[last_pop], 0
            mov dword[last_pop_tmp], 0

            power
            inc byte[operation_counter]
            call myCalc

        neg_power_main:

            mov dword[first_link], 0
            mov dword[last_pop], 0
            mov dword[last_pop_tmp], 0

            neg_power
            inc byte[operation_counter]
            call myCalc
            
            
      num_of_ones_main:
            clean_registers
            pop_link_from_stack
            mov ebx,dword[last_pop]
            cmp ebx,0
            je end_num_of_ones_main
            num_of_ones last_pop
            remove_and_free_list last_pop
        end_num_of_ones_main:
            inc byte[operation_counter]
            call myCalc
                
                
        quit_main: 
            mov dword [last_pop], 0
            cmp dword [stack_count], 0
            je done_free_before_exit

            pop_link_from_stack
            remove_and_free_list last_pop
            jmp quit_main

            done_free_before_exit:
                mov edx, dword [operation_counter]
                push edx
                push hex_format_1
                call printf
                mov edx, 0
                push edx
                call fflush
                quit 0

        debug_main:
            debug
            call myCalc
