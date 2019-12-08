[ORG 0x10000]


[BITS 64]



Kernel:
call video_cls

mov rsi,msg_map
call video_print

call page_table         ;call page table function

call video_cls

;PCI
mov rsi,msg_scan_device
call video_print
here1:

bus_loop:
    device_loop:
        function_loop:
            call get_pci_device
             check:
             mov bx, word[pci_header + PCI_CONF_SPACE.device_id]
             cmp bx, 0xffff
            je noCopy
            mov r14, qword[pci_header_memory]
            add r14, qword[pci_header_memory_offset]
            mov r15,r14
            mov r14, pci_header
            mov rcx, 32
            .loop:
            mov r10,qword[r14]
            mov qword[r15], r10
            add r14,8
            add r15,8
            dec rcx
            cmp rcx,0
            je .exit
            jmp .loop

            .exit:
            add qword[pci_header_memory_offset], 256     ;increment by 8 bytes (2 rows)
            inc qword[device_counter]                    ;a device was found

            noCopy:
             inc byte [function]
             cmp byte [function],8
        jne function_loop

        inc byte [device]
        mov byte [function],0x0
        cmp byte [device],32
    jne device_loop

inc byte [bus]
mov byte [device],0x0
cmp byte [bus],255
jne bus_loop

mov qword[pci_header_memory_offset] , 0
mov r9, qword[device_counter]

    
;printing pci details
loop6:
mov r15, qword[pci_header_memory]
add r15, qword[pci_header_memory_offset]
mov bl, byte[r15 + PCI_CONF_SPACE.class]
cmp bl,1
je  ata_found
here2:
mov rsi,msg_new_device
call video_print

call print_deviceID
call print_vendorID

add qword[pci_header_memory_offset],256
dec r9
cmp r9,1
je exit3
jmp loop6

ata_found:
mov rsi, ata_device_msg
call video_print
jmp here2
exit3:
mov rsi, msg_finish_scan
call video_print

mov rsi, newline
call video_print

;ATA 
xor rsi,rsi
mov rsi, msg_start_ata
call video_print
;call ata_copy_pci_header
channel_loop:
    mov qword [ata_master_var],0x0
    master_slave_loop:
        mov rdi,[ata_channel_var]
        mov rsi,[ata_master_var]
        call ata_identify_disk
        inc qword [ata_master_var]
        cmp qword [ata_master_var],0x2
    jl master_slave_loop

    inc qword [ata_channel_var]
    inc qword [ata_channel_var]
    cmp qword [ata_channel_var],0x4
jl channel_loop
    
mov rsi, newline
call video_print

call read_disk_sectors

xor rsi,rsi
mov rsi, newline
call video_print

;initializing idt and pit ticks will start
xor rsi,rsi
mov rsi,msg_start_pit
call video_print

call init_idt
call setup_idt
kernel_halt: 
    hlt
    jmp kernel_halt


;*******************************************************************************************************************
      %include "sources/includes/third_stage/pushaq.asm"
      %include "sources/includes/third_stage/pic.asm"
      %include "sources/includes/third_stage/idt.asm"
      %include "sources/includes/third_stage/pci.asm"
      %include "sources/includes/third_stage/video.asm"
      %include "sources/includes/third_stage/pit.asm"
      %include "sources/includes/third_stage/ata.asm"
      %include "sources/includes/third_stage/pagetable2.asm"
    
;*******************************************************************************************************************


colon db ':',0
comma db ',',0
newline db 13,0
device_counter dq   0       ;counter of devices

end_of_string  db 13        ; The end of the string indicator
start_location   dq  0x0  ; A default start position (Line # 8)

    hello_world_str db 'bypassed page table',13, 0  
    msg_map db 'Mapping the memory:',13, 0  
    msg_finish_scan db ' Scanning done ',13, 0   
    msg_start_pit db 'PIT ticks will start: ',13, 0   
    msg_start_ata db 'ATA devices details: ',13, 0 

    msg_finished_conv db 'Finished Char Conversion', 13, 0 
    msg_char    db '    The Hexa will be :', 13, 0 
    msg_begin_comp    db 'Reading disk sectors: ', 13, 0 
    msg_comp_str    db '    Begin Comp_str ', 13, 0 

    msg_found_deviceID1 db 'Found Device ID1 ',13, 0 
    msg_found_deviceID2 db 'Found Device ID2 ',13, 0 
    msg_found_deviceID3 db 'Found Vendor: ',13, 0 
    vendor_name db 'Intel Corporation ',13, 0
    msg_no_devices db 'Couldnt find devices, search the updated database at https://pci-ids.ucw.cz/ ',13, 0
    msg_found_deviceID4 db 'Not Found ',13, 0 
    msg_found_deviceID5 db '#', 13, 0 

    memory_tester_success db 'Memory Tester Succeeded!',13, 0   
    dot db '.'

    ata_channel_var dq 0
    ata_master_var dq 0

    bus db 0
    device db 0
    function db 0
    offset db 0
    hexa_digits       db "0123456789ABCDEF"         ; An array for displaying hexa decimal numbers
    ALIGN 4


times 65024-($-$$) db 0