;************************************** first_stage_data.asm **************************************
boot_drive db 0x0       ;mem variable for the disk drive number
lba_sector dw 0x1       ;mem variable to store next sector to be read; initialize by 1 as 0 is already done by hardware
spt dw 0x12             ;mem variable for sectors per track; default is floppy disk value
hpc dw 0x2              ;mem variable for heads per cylinder; default is floppy disk value
Cylinder dw 0x0         ;mem variable to be used when converting from lba to chs
Head db 0x0             ;mem variable to be used when converting from lba to chs
Sector dw 0x0           ;mem variable to be used when converting from lba to chs
disk_read_segment dw 0  ;mem variable for disk booting, segment
disk_read_offset dw 0   ;mem variable for disk booting, offset
;string messages for the first stage 
disk_error_msg db 'Disk Error', 13, 10, 0       ;in case of error when booting from disk drive
fault_msg db 'Unknown Boot Device', 13, 10, 0   ;in case couldnt identify the paramters for the boot device
booted_from_msg db 'Booted from ', 0            
floppy_boot_msg db 'Floppy', 13, 10, 0
drive_boot_msg db 'Disk', 13, 10, 0
greeting_msg db '1st Stage Loader', 13, 10, 0
second_stage_loaded_msg db 13,10,'2nd Stage loaded, press any key to resume!', 0    ;to continue to 2nd stage after success of the first one
dot db '.',0
newline db 13,10,0
