 ;************************************** read_disk_sectors.asm **************************************
      read_disk_sectors: ; This function will read a number of 512-sectors stored in DI 
                         ; The sectors should be loaded at the address starting at [disk_read_segment:disk_read_offset]
          pusha               ;push registers to the stack
          add di,[lba_sector]      ;as di has the last sector to read, so add it by the lba_sector variable
          ;function 2 of interrrupt 0x13 expects addresses of read sector will be in es and bx; where segment in es and offset in bx
          ;however, we can't load into as directly so will mov into ax first
          mov ax,[disk_read_segment]    ;mov to ax first
          mov es,ax                     ;now move to es
          add bx,[disk_read_offset]     ;setting bx to the offset 
          mov dl,[boot_drive]           ;mov to dl to read from the boot disk drive
          .read_sector_loop:
               call lba_2_chs           ;call this function to convert from lba to chs
               mov ah, 0x2              ;setting the function 0x2 that reads secotrs
               mov al,0x1               ;to this to read one sector only

               ;mov cx,[Cylinder]        ;store the mem variable of cylinder to cx
               ;shl cx,0xA               ;shift left by 10 bits 
               ;or cx,[Sector]            ;store the sector in the first 6 bits of cx
               mov cx, [Cylinder]       ;store the mem variable of cylinder to cx
               shl cx,0x8               ;shift left by 8 bits
               mov cl,[Sector]        ;mov now to half of cx which is cl
               
                         
               mov dh,[Head]            ;move the head mem variable to dh
               int 0x13                 ;issue the 0x13 interrupt to read
               jc .read_disk_error      ;if a problem happened and the carry flag=1 then there was an error in reading
               ;else print a dot to show that reading is in progress
               mov si,dot               ;to print a string its address must be in si       
               call bios_print          ;call the print function
               inc word [lba_sector]    ;now move to the next sector and repeat
               add bx,0x200             ;incremint the memory to the next address
               cmp word[lba_sector],di  ;as we stored in di the last sector to be read, then compare the values and if we reached this then we finished
               jl .read_sector_loop     ;else, keep looping
          jmp .finish    ;if they are equal then finish
          .read_disk_error:
          mov si,disk_error_msg         ;move into si the string "Disk Error"
          call bios_print               ;call print function
          jmp hang                      ;let the cpu hang
          .finish:
          popa                ;load the registers again
          ret