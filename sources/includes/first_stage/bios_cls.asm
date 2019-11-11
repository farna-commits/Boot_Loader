;************************************** bios_cls.asm **************************************      
      bios_cls:   ; A routine to initialize video mode 80x25 which also clears the screen
      pusha ;push the current status of the registers on the stack
      mov ah,0x0 ;setting ah as 0 sets the video mode 
      mov al,0x3 ;color text mode 
      int 0x10 ;interrupt the cpu with 0x10
      popa  ;pop from the stack the registers that were saved on the stack before 
      ret
