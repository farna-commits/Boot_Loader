 ;************************************** lba_2_chs.asm **************************************
 lba_2_chs:  ; Convert the value store in [lba_sector] to its equivelant CHS values and store them in [Cylinder],[Head], and [Sector] respectivly
                ;spt: sectors per track    hpc: heads per cylinder 
                ;Sector = lba_sector % spt +1
                ;Cylinder = lba_sector/spt / hpc (quotient)
                ;Head = lba_sector/spt % hpc (reminder)

        pusha                   ;push the registers to the stack
        xor dx,dx               ;set dx as 0
        mov ax, [lba_sector]    ;move into ax the variable that contains which sector to read next in order to do division
        div word [spt]          ;divide Ax/spt which is lba_sector/spt and reminder will be saved in dx while quiotaint in ax
        inc dx                  ;add 1 to the divide result to obtain Sector 
        mov [Sector], dx        ;move the result to the memory variable
        xor dx,dx               ;set dx=0 to use again
        div word [hpc]          ;Note:Ax containts lba_sector/spt; thus mod by hpc directly to get Cylinder
        mov [Cylinder], ax      ;move the quotient result into the memory variable
        mov [Head], dl          ;move the reminder result into the memory variable (use dl as we need only half the word and dl is half dx)
        popa                    ;load the pushed registers from the stack
        ret
                    