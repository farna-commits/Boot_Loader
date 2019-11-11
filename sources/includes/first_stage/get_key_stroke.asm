;************************************** get_key_stroke.asm **************************************      
        get_key_stroke: ; A routine to print a confirmation message and wait for key press to jump to second boot stage
        pusha   ;push the current status of the registers on the stack
        mov ah,0x0      ;initialize ah by 0
        int 0x16        ;interrupt 0x16 used to take keyboard input from the user 
        popa            ;pop from the stack the registers that were saved on the stack before 
        ret  