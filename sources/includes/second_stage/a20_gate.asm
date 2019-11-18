check_a20_gate:
    pusha                                   ; Save all general purpose registers on the stack
    mov ax,0x2402                           ;using the function 0x2402 of interrupt 0x15
    int 0x15                                ;issue interrupt 0x15
    jc .error                               ;if a problem happened the carry flag should be set to 1, if so go to label error and hang
    cmp al,0x0                              ;check if the carrry flag isnt set 
    je .enable_a20                          ;if flag isnt set enable the gate

.enable_a20:
    mov ax,0x2401                           ;use the function 0x2401 of interrupt 0x15
    int 0x15                                ;issue interrupt 0x15
    jc .error                               ;if carry flag is set then go to error
    ;print a flag to say that a20 was enabled 
    mov si, a20_enabled_msg
    call .print
    jmp .Exit
    ;then go check
    jmp check_a20_gate                      ;if error check the a20 gate
    ;popa                                    ;Restore all general purpose registers from the stack
        mov si, a20_enabled_msg
        call bios_print
   ; ret


;if an error happened hang the cpu 
.error:
    ;we have two chances of error
    cmp ah, 0x1                             ;compare if ah = 0x1
    je .equal                               ;if equal go to the label, then function isnt supported
    ;else then keyboard controller error
    mov si, keyboard_controller_error_msg   ;move the string message to si
    jmp .print                              ;call the print

    .equal:
    mov si, a20_function_not_supported_msg  ;move to the string message to si
    jmp .print                              ;call the print

    .print:
        call bios_print                     ;call the print 
       ; jmp check_a20_gate                  ;loop again
        ret

.Exit:
popa 
ret