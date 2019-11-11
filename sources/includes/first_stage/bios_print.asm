;************************************** bios_print.asm **************************************      
      bios_print:       ; A subroutine to print a string on the screen using the bios int 0x10.
                        ; Expects si to have the address of the string to be printed.
                        ; Will loop on the string characters, printing one by one. 
                        ; Will Stop when encountering character 0. 
      pusha       ;push all the registers on the stack
      .print_loop:
            xor ax,ax   ;set ax as 0
            lodsb       ;load the byte pointed by si into al, then increminting si
            or al, al   ;moving al into itself (x or x = x)
            jz .done    ;if al = 0, go to the done label
            mov ah, 0x0E      ;0x0E is printing a character function interrupt
            int 0x10    ;issue interrupt 0x10, which will print the character in al
            jmp .print_loop
      .done: ;if null character (0) is reached 
      popa  ;load the registers that were pushed
      ret