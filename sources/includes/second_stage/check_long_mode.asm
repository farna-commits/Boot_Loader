        
        mov si, a20_enabled_msg
        call bios_print   

        
        
        
        check_long_mode:
            pusha                           ; Save all general purpose registers on the stack
            call check_cpuid_support        ; Check if cpuid instruction is supported by the CPU
            call check_long_mode_with_cpuid ; check long mode using cpuid
            popa                            ; Restore all general purpose registers from the stack
            ret

        check_cpuid_support:
            pusha               ; Save all general purpose registers on the stack
            pushfd              ;push the eflags to use at the end of the function (taking a snapshot)
            pushfd              ;push the eflags again, but to use in comparison (taking a 2nd snapchot)
            pushfd              ;push once more but for moving the value to eax (no mov on flags)
            pop eax             ;similar to mov eax,eflags
            xor eax,0x0200000   ;flip the bit in position 21
            push eax            ;push the new value for eax after flipping 
            popfd               ;pop the top value
            pushfd              ;push it in order to move it to eax (again, no mov with flags)
            pop eax             ;similar to mov eax,eflags
            pop ecx             ;pop the 2nd snapshot taken for the eflags
            ;if the flipped bit was really written into, then xoring this bit with the original value in eax will give 1
            xor eax,ecx         
            and eax,0x0200000   ;zero all the bits except 21
            cmp eax,0x0         ;is the 21 bit written into? if yes then this comparison must be wrong
            jne .cpuid_supported    ;if not equal 0 (ie eqal 1) then CPUid is supported
            mov si,cpuid_not_supported  ;else it's not, so move address of string "not supported" to si to print
            call bios_print     ;call print function that prints what's inside si (address)
            jmp hang            ;hang the cpu
            .cpuid_supported:
            mov si,cpuid_supported  ;if supported, then display the supported string message
            call bios_print ;again the print what;s in si function
            popfd               ;restore the first snapshot of the eflags
            popa                ; Restore all general purpose registers from the stack
            ret

        check_long_mode_with_cpuid:
            pusha                                   ; Save all general purpose registers on the stack
            mov eax,0x80000000                      ;this function determines the maximum function number to be used
            cpuid                                   ;like calling a function
            cmp eax,0x80000001                      ;compare the max number we have now in eax with 0x80000001
            jl .long_mode_not_supported             ;if max<0x80000001 then long mode isnt supported
            mov eax,0x80000001                      ;else, then 0x80000001 function is supported and we call it to get processor extended features
            cpuid
            and edx,0x20000000                      ;keep only bit 29 if it is set (29 is long mode bit)
            cmp edx,0                               ;if this long mode bit isnt set (=1) then long mode isnt supported
            je .long_mode_not_supported             ;if longmode bit =0, then not supported
            mov si,long_mode_supported_msg          ;else, it is supported; so move the string that says so into si to print
            call bios_print                         ;printing function
            jmp .exit_check_long_mode_with_cpuid    ;go to this label to pop the registers and exit the function
            .long_mode_not_supported:
            mov si,long_mode_not_supported_msg      ;move the not supported string to print
            call bios_print
            jmp hang                                ;hang the cpu
            .exit_check_long_mode_with_cpuid:
            popa                                ; Restore all general purpose registers from the stack
            ret