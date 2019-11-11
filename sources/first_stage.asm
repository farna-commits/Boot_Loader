;*******************************************************************************************************
;**************                          MyOS First Stage Boot Loader                     **************
;*******************************************************************************************************
[ORG 0x7c00]      ; Since this code will be loaded at 0x7c00 we need all the addresses to be relative to 0x7c00
                  ; The ORG directive tells the linker to generate all addresses relative to 0x7c00
;*********************************************** Macros ************************************************
%define SECOND_STAGE_CODE_SEG       0x0000      ; The segment address where we should load the second stage boot laoder
%define SECOND_STAGE_OFFSET         0xC000      ; The offset where we should start loading the second stage boot loader
%define THIRD_STAGE_CODE_SEG        0x1000      ; The segment address where we should load the second stage boot laoder
%define THIRD_STAGE_OFFSET          0x0000      ; The offset where we should start loading the second stage boot loader
%define STACK_OFFSET                0xB000      ; The offset of the stack. The stack should grow upward from 0xB000 - 0x8000  
;********************************************* Main Program ********************************************
      xor ax,ax                           ; Initialize ax to zero.
      mov ds,ax                           ; Store 0 in DS to set data segment to 0x0000.
      mov ss,ax                           ; Store 0 in SS to set stack segment to 0x0000.
      mov sp,STACK_OFFSET                 ; Stack grows upwards so we have atleast 0x2000 = 8192 bytes = 8 K stack large
      call bios_cls                       ; Clear the screen
      mov si,greeting_msg                 ; Print the greeting message
      call bios_print                     
      call detect_boot_disk               ; Call detect_boot_disk to set all disk parameters and make disk ready for reading sectors.
      mov di,0x8
      mov word [disk_read_segment],SECOND_STAGE_CODE_SEG
      mov word [disk_read_offset],SECOND_STAGE_OFFSET
      call read_disk_sectors              ; Read exactly 4 KB (8 512-sectors) which have the second stage boot loader
      mov di,0x7F
      mov word [disk_read_segment],THIRD_STAGE_CODE_SEG
      mov word [disk_read_offset],THIRD_STAGE_OFFSET
      call read_disk_sectors   ; Read exactly 63.5 KB which contains the third stage boot loader, i.e. a 64K segment less 512 bytes disk sector
                               ; The reason that we could not load the last sector of the 64 K is that the load address of that sector is 
                               ; 0x1000:0xFE00, and accounding to the INT 0x13/fun2 that we will use to read the sectors, the memory address 
                               ; that the sector will be loaded to need to plus the sector size need to be within the same segment
                               ; 0xFE00+0x200 = 0x10000 which is an address outside the memory segment. 

; Enable the below code when you load successfully the second stage bootloader sectors
      mov si,second_stage_loaded_msg      ; Print a message indicated that second stage boot loader sectors are loaded from disl
      call bios_print
      call get_key_stroke                 ; Wait for key storke to jump to second boot stage
      jmp SECOND_STAGE_OFFSET             ; We perform what we call a long jump as we are going to jump to another segment jmp ox1000:0x0000

      hang:             ; An infinite loop just in case interrupts are enabled. More on that later.
            hlt         ; Halt will suspend the execution. This will not return unless the processor got interrupted.
            jmp hang    ; Jump to hang so we can halt again.
;************************************ Data Declaration and Definition **********************************
      %include "sources/includes/first_stage/first_stage_data.asm"
;************************************ Subroutines/Functions Includes ***********************************
      %include "sources/includes/first_stage/detect_boot_disk.asm"
      %include "sources/includes/first_stage/load_boot_drive_params.asm"
      %include "sources/includes/first_stage/lba_2_chs.asm"
      %include "sources/includes/first_stage/read_disk_sectors.asm"
      %include "sources/includes/first_stage/bios_cls.asm"
      %include "sources/includes/first_stage/bios_print.asm"
      %include "sources/includes/first_stage/get_key_stroke.asm"
;**************************** Padding and Signature **********************************

      times 510-($-$$) db 0   ; $$ refers to the start address of the current section, $ refers to the current address.
                              ; ($-$$) is the size of the above code/data
                              ; times take a count and a data item and repeat it as many time as the value of count.
                              ; We subtract ($-$$) from 510 and use "times" to fill in the rest of the 510 with zero bytes.
                              ; We use 510 instead of 512 to reserve the last two bytes for the signature below. 
      db 0x55,0xAA            ; Boot sector MBR signature


