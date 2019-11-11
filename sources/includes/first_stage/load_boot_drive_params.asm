;************************************** load_boot_drive_params.asm **************************************
      load_boot_drive_params: ; A subroutine to read the [boot_drive] parameters and update [hpc] and [spt]
            pusha             ;push registers to the stack
            ;the function 0x8 of interrupt 0x13 needs that es and di be set as 0 to avoid bugs
            xor di,di         ;set di as 0
            mov es,di         ;set es as 0
            mov ah,0x8        ;get function 0x8 of interrupt  0x13 that gets disk parameters 
            mov dl,[boot_drive]     ;move into dl the disk number we want its parameters 
            int 0x13          ;issue interrupt 13
            inc dh            ;dh has the last head so incriment it to get value of head/cylinder 
            mov word [hpc],0x0      ;set hpc as 0
            mov [hpc+1],dh    ;move dh into the lower byte of hpc
            and cx,0000000000111111b ; Extract the 6 right most bits of CX that has the sectors/track (b means binary)
            mov word [spt],cx       ;store sector value in sectors per track
            popa              ;load the registers from the stack
            ret