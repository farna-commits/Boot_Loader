;************************************** detect_boot_disk.asm **************************************      
      detect_boot_disk: ; A subroutine to detect the the storage device number of the device we have booted from
                        ; After the execution the memory variable [boot_drive] should contain the device number
                        ; Upon booting the bios stores the boot device number into DL
            pusha ;push all registers on the stack
            mov si,fault_msg ;store in si the fault message that will be showed if we couldnt detect 
            xor ax,ax         ;set ax as 0
            int 13h           ;issue the interupt 13h which is a BIOS one
            jc .exit_with_error     ;if the carry flag is = 1 then go to this label 
            ;else we need to know that are we booting from:
            mov si,booted_from_msg  ;store in si the message that says "booted from:" 
            call bios_print         ;call another function on the enviroment that prints string whose address in si
            mov [boot_drive], dl    ;move the boot drive number from dl
            ;if dl=0, then we are booting from a floppy 
            cmp dl,0
            je .floppy ;if dl is 0 go to the label of floppy
            ;if it is not floppy, then it is hard disk, then we get the boot drive parametrs (as floppy is default)
            call load_boot_drive_params ;call this function that gets the parameters
            mov si,drive_boot_msg   ;store in si the string "Disk"
            jmp .finish             ;go to finish
            .floppy:
            mov si,floppy_boot_msg  ;store in si the string "Floppy"
            jmp .finish       ;go to finish
            .exit_with_error:       ;there was an error in the detection so hang the CPU
            jmp hang
            .finish:
            call bios_print         ;print what is either in si, DIsk or Floppy
            popa        ;load the registers that were pushed 
            ret
