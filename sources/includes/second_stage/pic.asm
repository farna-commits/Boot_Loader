%define MASTER_PIC_COMMAND_PORT     0x20
%define SLAVE_PIC_COMMAND_PORT      0xA0
%define MASTER_PIC_DATA_PORT        0x21
%define SLAVE_PIC_DATA_PORT         0xA1


    disable_pic:    
        pusha   ; Save all general purpose registers on the stack
        mov al,0xFF                     ;writing 0xff disables the master and the slave 
        out MASTER_PIC_DATA_PORT,al     ;write(out) in the master port 0xff to disable it
        out SLAVE_PIC_DATA_PORT,al      ;write(out) in the slave port 0xff to disable it
        nop ;no operation instruction to give time for the controllers to shut down
        nop ;no operation instruction to give time for the controllers to shut down
        mov si, pic_disabled_msg        ;move into si string to print 
        call bios_print                 ;call the print function 
        popa        ; Restore all general purpose registers from the stack
        ret