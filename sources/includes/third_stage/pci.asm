;*******************************************************************************************************************
%define CONFIG_ADDRESS  0xcf8
%define CONFIG_DATA     0xcfc

ata_device_msg db 'Found ATA Controller',13,10,0
pci_header times 512 db 0

pci_header_memory             dq   0xdac000     ;place in memory to copy the devices in memory
pci_header_memory_offset      dq   0x0           ;offset from the address

;messages
msg_new_device db 'New Device: ',13,0   
msg_scan_device db ' Scanning PCI Devices ',13,0   
msg_deviceID db 'Device ID: ',0   
msg_vendorID db 'Vendor ID: ',0   
msg_space db ' ',0   



struc PCI_CONF_SPACE 
.vendor_id          resw    1
.device_id          resw    1
.command            resw    1
.status             resw    1
.rev                resb    1
.prog_if            resb    1
.subclass           resb    1
.class              resb    1
.cache_line_size    resb    1
.latency            resb    1
.header_type        resb    1
.bist               resb    1
.bar0               resd    1
.bar1               resd    1
.bar2               resd    1
.bar3               resd    1
.bar4               resd    1
.bar5               resd    1
.reserved           resd    2
.int_line           resb    1
.int_pin            resb    1
.min_grant          resb    1
.max_latency        resb    1
.data               resb    192
endstruc


    get_pci_device:
    pushaq
    ;Counters
    ;Compose the Config Address Register (32-bis):
        ;  Bit 23-16 : bus (so we shift left 16 bits))
        ;  Bit 15-11 : device (so we shift left 11 bits))
        ;  Bit 10-8 : function (so we shift left 8 bits))
        ;  Bit 7-2 : so we clear the last two bytes by & 0xfc
        ;  Bit 31 : Enable bit, and to set it we | 0x80000000
        ;  ((bus << 16) | (device << 11) | (function << 8) | (offset & 0xfc) | ( 0x80000000)) 
      xor rax,rax
      xor rbx,rbx        ;((bus << 16)
      mov bl,[bus]
      shl ebx,16
      or eax,ebx
      xor rbx,rbx     ;|(device << 11)
      mov bl,[device]
      shl ebx,11
      or eax,ebx 
      xor rbx,rbx      ;| (function << 8)
      mov bl,[function]
      shl ebx,8
      or eax,ebx 
      or eax,0x80000000  ;| ( 0x80000000)
      xor rsi,rsi       ; Zero out RSI as we will use it as an offset
      pci_config_space_read_loop:
      push rax          ; Save Initial Command Register
      ;| (offset & 0xfc)
      or rax,rsi
      and al,0xfc; This ensures the the last 2 bits are zeros
      ; Write to port from Command Port
      mov dx,CONFIG_ADDRESS
      out dx,eax
      ; Write to port from Data Port
      mov dx,CONFIG_DATA
      xor rax,rax 
      in eax,dx
      ; Store the double word (32-bit) read into a memory region
      mov[pci_header+rsi],eax
      add rsi,0x4; Advance Offsetpoprax; Restore the Initial Command Register
      pop rax
      cmp rsi,0xff; Check if we have read the whole 256 Configuration Space
      jl pci_config_space_read_loop


      ;check if device 


      ;call copy_to_memory         ;call the copying function
      ;call check_deviceID
  popaq
  ret


 ;to take each pci header table to the memory
 ;copy two rows at a time (1 register->8bytes ; 1 row->4 bytes)
; copy_to_memory:
; pushaq
; ;base-> r8 ; base+offset ->r9 ; counter -> r10
; ;xor r8, r8
; mov r8, qword[pci_header_memory]          ;move the base address
; ;xor r9, r9
; xor r10, r10    ;counter of rows 
; xor r11, r11    ;offset for pci_header    
; ;mov qword[pci_header_memory_offset], 0
; mov r9, qword[pci_header_memory_offset+r8]
; mov r12, pci_header              ;take a copy
; mov r9, r12
;   .loop:
 ; mov r9, qword[r8+pci_header_memory_offset]   ;base+offset to 
  
  ;add r9,r8



  ;mov qword[r9], r12
  ; mov rdi, qword[r9]
  ; call bios_print_hexa

  ; mov rsi, newline
  ; call video_print
  

  ; add r11, 256           ;increment pci_header offset
  ; inc r10               ;increment the counter of rows
  ; cmp r10,32     ;compare with 8 (16 row 16 x 4bytes = 64)
  ;jl .loop
;   add qword[pci_header_memory_offset], 256     ;increment by 8 bytes (2 rows)
; ;mov qword[pci_header_memory_offset], 0x0
; mov r13, qword[pci_header_memory_offset]
; add r13, r8
; mov rdi, qword[r13]
; call bios_print_hexa
; mov rsi, newline
; call video_print
popaq
ret

check_deviceID:
pushaq
; mov qword[pci_header_memory_offset], 0x0
; mov r8, qword[pci_header_memory]          ;move the base address
; mov r9, qword[r8+pci_header_memory_offset]   ;base+offset to 

;   mov r15, qword[r9+PCI_CONF_SPACE.vendor_id]     ;extract the device id using the struct
; ; ; ;mov r15, '#'
;   mov rdi, r15
;   call bios_print_hexa

popaq
ret


print_deviceID:
pushaq
    mov rsi, msg_space
    call video_print
    mov rsi, msg_deviceID
    call video_print
    mov rsi, msg_space
    call video_print
    mov rdi, qword[r15 + PCI_CONF_SPACE.device_id]
    call bios_print_hexa
    mov rsi,newline
    call video_print
popaq
ret

print_vendorID:
pushaq
    mov rsi, msg_space
    call video_print
    mov rsi, msg_vendorID
    call video_print
    mov rsi, msg_space
    call video_print
    mov rdi, qword[r15 + PCI_CONF_SPACE.vendor_id]
    call bios_print_hexa
    mov rsi,newline
    call video_print
popaq
ret